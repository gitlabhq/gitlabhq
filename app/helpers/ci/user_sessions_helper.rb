module Ci
  module UserSessionsHelper
    def generate_oauth_salt
      SecureRandom.hex(16)
    end

    def generate_oauth_hmac(salt, return_to)
      return unless return_to
      digest = OpenSSL::Digest.new('sha256')
      key = Gitlab::Application.secrets.db_key_base + salt
      OpenSSL::HMAC.hexdigest(digest, key, return_to)
    end

    def generate_oauth_state(return_to)
      return unless return_to
      salt = generate_oauth_salt
      hmac = generate_oauth_hmac(salt, return_to)
      "#{salt}:#{hmac}:#{return_to}"
    end

    def get_ouath_state_return_to(state)
      state.split(':', 3)[2] if state
    end

    def is_oauth_state_valid?(state)
      return true unless state
      salt, hmac, return_to = state.split(':', 3)
      return false unless return_to
      hmac == generate_oauth_hmac(salt, return_to)
    end
  end
end
