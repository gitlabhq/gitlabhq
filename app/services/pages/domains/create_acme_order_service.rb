# frozen_string_literal: true

module Pages
  module Domains
    class CreateAcmeOrderService
      attr_reader :pages_domain

      def initialize(pages_domain)
        @pages_domain = pages_domain
      end

      def execute
        lets_encrypt_client = Gitlab::LetsEncrypt::Client.new
        order = lets_encrypt_client.new_order(pages_domain.domain)

        challenge = order.new_challenge

        private_key = OpenSSL::PKey::RSA.new(4096)
        saved_order = pages_domain.acme_orders.create!(
          url: order.url,
          expires_at: order.expires,
          private_key: private_key.to_pem,

          challenge_token: challenge.token,
          challenge_file_content: challenge.file_content
        )

        challenge.request_validation

        ServiceResponse.success(payload: { acme_order: saved_order })
      rescue Acme::Client::Error => e
        ServiceResponse.error(message: e.message, payload: { acme_order: saved_order })
      end
    end
  end
end
