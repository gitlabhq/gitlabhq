# frozen_string_literal: true

module Gitlab
  module LetsEncrypt
    class Client
      PRODUCTION_DIRECTORY_URL = 'https://acme-v02.api.letsencrypt.org/directory'
      STAGING_DIRECTORY_URL = 'https://acme-staging-v02.api.letsencrypt.org/directory'

      def new_order(domain_name)
        ensure_account

        acme_order = acme_client.new_order(identifiers: [domain_name])

        ::Gitlab::LetsEncrypt::Order.new(acme_order)
      end

      def load_order(url)
        ensure_account

        # rubocop: disable CodeReuse/ActiveRecord
        ::Gitlab::LetsEncrypt::Order.new(acme_client.order(url: url))
        # rubocop: enable CodeReuse/ActiveRecord
      end

      def load_challenge(url)
        ensure_account

        ::Gitlab::LetsEncrypt::Challenge.new(acme_client.challenge(url: url))
      end

      def terms_of_service_url
        acme_client.terms_of_service
      end

      def enabled?
        return false unless Feature.enabled?(:pages_auto_ssl)

        Gitlab::CurrentSettings.lets_encrypt_terms_of_service_accepted
      end

      private

      def acme_client
        @acme_client ||= ::Acme::Client.new(private_key: private_key, directory: acme_api_directory_url)
      end

      def private_key
        @private_key ||= OpenSSL::PKey.read(Gitlab::Application.secrets.lets_encrypt_private_key)
      end

      def admin_email
        Gitlab::CurrentSettings.lets_encrypt_notification_email
      end

      def contact
        "mailto:#{admin_email}"
      end

      def ensure_account
        raise 'Acme integration is disabled' unless enabled?

        @acme_account ||= acme_client.new_account(contact: contact, terms_of_service_agreed: true)
      end

      def acme_api_directory_url
        if Rails.env.production?
          PRODUCTION_DIRECTORY_URL
        else
          STAGING_DIRECTORY_URL
        end
      end
    end
  end
end
