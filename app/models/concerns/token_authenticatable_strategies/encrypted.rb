# frozen_string_literal: true

module TokenAuthenticatableStrategies
  class Encrypted < Base
    def find_token_authenticatable(token, unscoped = false)
      return unless token

      encrypted_value = Gitlab::CryptoHelper.aes256_gcm_encrypt(token)
      token_authenticatable = relation(unscoped)
        .find_by(encrypted_field => encrypted_value)

      if fallback?
        token_authenticatable ||= fallback_strategy
          .find_token_authenticatable(token)
      end

      token_authenticatable
    end

    def get_token(instance)
      raw_token = instance.read_attribute(encrypted_field)
      token = Gitlab::CryptoHelper.aes256_gcm_decrypt(raw_token)

      token || (fallback_strategy.get_token(instance) if fallback?)
    end

    def set_token(instance, token)
      raise ArgumentError unless token.present?

      instance[encrypted_field] = Gitlab::CryptoHelper.aes256_gcm_encrypt(token)
    end

    protected

    def fallback_strategy
      @fallback_strategy ||= TokenAuthenticatableStrategies::Insecure
        .new(klass, token_field, options)
    end

    def token_set?(instance)
      raw_token = instance.read_attribute(encrypted_field)
      raw_token ||= instance.read_attribute(token_field) if fallback?

      raw_token.present?
    end

    def encrypted_field
      @encrypted_field ||= "#{@token_field}_encrypted"
    end
  end
end
