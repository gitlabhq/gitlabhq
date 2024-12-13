# frozen_string_literal: true

module Pages
  module Domains
    class ObtainLetsEncryptCertificateService
      # time for processing validation requests for acme challenges
      # 5-15 seconds is usually enough
      CHALLENGE_PROCESSING_DELAY = 1.minute.freeze

      # time LetsEncrypt ACME server needs to generate the certificate
      # no particular SLA, usually takes 10-15 seconds
      CERTIFICATE_PROCESSING_DELAY = 1.minute.freeze

      attr_reader :pages_domain

      def initialize(pages_domain)
        @pages_domain = pages_domain
      end

      def execute
        pages_domain.acme_orders.expired.delete_all
        acme_order = pages_domain.acme_orders.first

        unless acme_order
          service_response = ::Pages::Domains::CreateAcmeOrderService.new(pages_domain).execute
          if service_response.error?
            save_order_error(service_response[:acme_order], service_response.message)
            return
          end

          PagesDomainSslRenewalWorker.perform_in(CHALLENGE_PROCESSING_DELAY, pages_domain.id)
          return
        end

        api_order = ::Gitlab::LetsEncrypt::Client.new.load_order(acme_order.url)

        begin
          # https://www.rfc-editor.org/rfc/rfc8555#section-7.1.6 - statuses diagram
          case api_order.status
          when 'ready'
            api_order.request_certificate(private_key: acme_order.private_key, domain: pages_domain.domain)
            PagesDomainSslRenewalWorker.perform_in(CERTIFICATE_PROCESSING_DELAY, pages_domain.id)
          when 'valid'
            save_certificate(acme_order.private_key, api_order)
            acme_order.destroy!
          when 'invalid'
            save_order_error(acme_order, api_order.challenge_error)
          end
        rescue Acme::Client::Error => e
          save_order_error(acme_order, e.message)
        end
      end

      private

      def save_certificate(private_key, api_order)
        certificate = api_order.certificate
        pages_domain.update!(gitlab_provided_key: private_key, gitlab_provided_certificate: certificate)
      end

      def save_order_error(acme_order, acme_error_message)
        log_error(acme_error_message)

        pages_domain.assign_attributes(auto_ssl_failed: true)
        pages_domain.save!(validate: false)

        acme_order&.destroy!

        NotificationService.new.pages_domain_auto_ssl_failed(pages_domain)
      end

      def log_error(acme_error_message)
        Gitlab::AppLogger.error(
          message: "Failed to obtain Let's Encrypt certificate",
          acme_error: acme_error_message,
          project_id: pages_domain.project_id,
          pages_domain: pages_domain.domain
        )
      end
    end
  end
end
