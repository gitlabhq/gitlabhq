# frozen_string_literal: true

module Gitlab
  module Kas
    # The name of the cookie that will be used for the KAS cookie
    COOKIE_KEY = '_gitlab_kas'
    DEFAULT_ENCRYPTED_COOKIE_CIPHER = 'aes-256-gcm'

    class UserAccess
      class << self
        def enabled?
          ::Gitlab::Kas.enabled?
        end

        def encrypt_public_session_id(data)
          encryptor.encrypt_and_sign(data.to_json, purpose: public_session_id_purpose)
        end

        def decrypt_public_session_id(data)
          encrypted_data = data.delete_prefix(session_cookie_token_prefix)
          decrypted = encryptor.decrypt_and_verify(encrypted_data, purpose: public_session_id_purpose)
          ::Gitlab::Json.parse(decrypted)
        end

        def valid_authenticity_token?(request, session, masked_authenticity_token)
          # rubocop:disable GitlabSecurity/PublicSend
          if ::Gitlab.next_rails?
            controller = ActionController::Base.new
            controller.set_request!(ActionDispatch::Request.new(request.env).dup)
            controller.send(:valid_authenticity_token?, session, masked_authenticity_token)
          else
            ActionController::Base.new.send(
              :valid_authenticity_token?, session, masked_authenticity_token
            )
          end
          # rubocop:enable GitlabSecurity/PublicSend
        end

        def cookie_data(public_session_id)
          uri = URI(::Gitlab::Kas.tunnel_url)
          value = session_cookie_token_prefix + encrypt_public_session_id(public_session_id)

          cookie = {
            value: value,
            expires: 1.day,
            httponly: true,
            path: uri.path.presence || '/',
            secure: Gitlab.config.gitlab.https
          }
          # Only set domain attribute if KAS is on a subdomain.
          # When on the same domain, we can omit the attribute.
          gitlab_host = Gitlab.config.gitlab.host
          cookie[:domain] = gitlab_host if uri.host.end_with?(".#{gitlab_host}")

          cookie
        end

        private

        def encryptor
          action_dispatch_config = Gitlab::Application.config.action_dispatch
          serializer = ActiveSupport::MessageEncryptor::NullSerializer
          key_generator = ::Gitlab::Application.key_generator

          cipher = action_dispatch_config.encrypted_cookie_cipher || DEFAULT_ENCRYPTED_COOKIE_CIPHER
          salt = action_dispatch_config.authenticated_encrypted_cookie_salt
          key_len = ActiveSupport::MessageEncryptor.key_len(cipher)
          secret = key_generator.generate_key(salt, key_len)

          ActiveSupport::MessageEncryptor.new(secret, cipher: cipher, serializer: serializer)
        end

        def public_session_id_purpose
          "kas.user_public_session_id"
        end

        def session_cookie_token_prefix
          Rails.application.config.session_options[:session_cookie_token_prefix] || ''
        end
      end
    end
  end
end
