# frozen_string_literal: true

module PagesDomains
  class CreateAcmeOrderService
    attr_reader :pages_domain
    # TODO: remove this hack after https://gitlab.com/gitlab-org/gitlab/issues/30146 is implemented
    # This makes GitLab automatically retry the certificate obtaining process every 2 hours if process wasn't finished
    SHORT_EXPIRATION_DELAY = 2.hours

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
        expires_at: [order.expires, SHORT_EXPIRATION_DELAY.from_now].min,
        private_key: private_key.to_pem,

        challenge_token: challenge.token,
        challenge_file_content: challenge.file_content
      )

      challenge.request_validation
      saved_order
    end
  end
end
