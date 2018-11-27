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

    def ensure_token(instance)
      # TODO, tech debt, because some specs are testing migrations, but are still
      # using factory bot to create resources, it might happen that a database
      # schema does not have "#{token_name}_encrypted" field yet, however a bunch
      # of models call `ensure_#{token_name}` in `before_save`.
      #
      # In that case we are using insecure strategy, but this should only happen
      # in tests, because otherwise `encrypted_field` is going to exist.

      return super if instance.has_attribute?(encrypted_field)

      if fallback?
        fallback_strategy.ensure_token(instance)
      else
        raise ArgumentError, 'No fallback defined when encrypted field is missing!'
      end
    end

    def get_token(instance)
      encrypted_token = instance.read_attribute(encrypted_field)
      token = Gitlab::CryptoHelper.aes256_gcm_decrypt(encrypted_token)

      token || (fallback_strategy.get_token(instance) if fallback?)
    end

    def set_token(instance, token)
      raise ArgumentError unless token.present?

      instance[encrypted_field] = Gitlab::CryptoHelper.aes256_gcm_encrypt(token)
      fallback_strategy.set_token(instance, nil) if fallback?
      token
    end

    protected

    def fallback_strategy
      @fallback_strategy ||= TokenAuthenticatableStrategies::Insecure
        .new(klass, token_field, options)
    end

    def token_set?(instance)
      raw_token = instance.read_attribute(encrypted_field)
      raw_token ||= (fallback_strategy.get_token(instance) if fallback?)

      raw_token.present?
    end

    def encrypted_field
      @encrypted_field ||= "#{@token_field}_encrypted"
    end
  end
end
