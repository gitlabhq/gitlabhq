# frozen_string_literal: true

module PagesDomains
  class CreateAcmeOrderService
    # elliptic curve algorithm to generate the private key
    ECDSA_CURVE = "prime256v1"

    attr_reader :pages_domain

    def initialize(pages_domain)
      @pages_domain = pages_domain
    end

    def execute
      lets_encrypt_client = Gitlab::LetsEncrypt::Client.new
      order = lets_encrypt_client.new_order(pages_domain.domain)

      challenge = order.new_challenge

      private_key = if Feature.enabled?(:pages_lets_encrypt_ecdsa, pages_domain.project)
                      OpenSSL::PKey::EC.generate(ECDSA_CURVE)
                    else
                      OpenSSL::PKey::RSA.new(4096)
                    end

      saved_order = pages_domain.acme_orders.create!(
        url: order.url,
        expires_at: order.expires,
        private_key: private_key.to_pem,

        challenge_token: challenge.token,
        challenge_file_content: challenge.file_content
      )

      challenge.request_validation
      saved_order
    end
  end
end
