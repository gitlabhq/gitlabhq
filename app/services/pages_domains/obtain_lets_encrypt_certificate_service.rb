# frozen_string_literal: true

module PagesDomains
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
        ::PagesDomains::CreateAcmeOrderService.new(pages_domain).execute
        PagesDomainSslRenewalWorker.perform_in(CHALLENGE_PROCESSING_DELAY, pages_domain.id)
        return
      end

      api_order = ::Gitlab::LetsEncrypt::Client.new.load_order(acme_order.url)

      # https://tools.ietf.org/html/rfc8555#section-7.1.6 - statuses diagram
      case api_order.status
      when 'ready'
        api_order.request_certificate(private_key: acme_order.private_key, domain: pages_domain.domain)
        PagesDomainSslRenewalWorker.perform_in(CERTIFICATE_PROCESSING_DELAY, pages_domain.id)
      when 'valid'
        save_certificate(acme_order.private_key, api_order)
        acme_order.destroy!
        # when 'invalid'
        # TODO: implement error handling
      end
    end

    private

    def save_certificate(private_key, api_order)
      certificate = api_order.certificate
      pages_domain.update!(gitlab_provided_key: private_key, gitlab_provided_certificate: certificate)
    end
  end
end
