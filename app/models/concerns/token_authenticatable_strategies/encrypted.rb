# frozen_string_literal: true

module TokenAuthenticatableStrategies
  class Encrypted < Base
    def initialize(*)
      super

      if migrating? && fallback?
        raise ArgumentError, '`fallback` and `migrating` options are not compatible!'
      end
    end

    def find_token_authenticatable(token, unscoped = false)
      return if token.blank?

      if fully_encrypted?
        return find_by_encrypted_token(token, unscoped)
      end

      if fallback?
        find_by_encrypted_token(token, unscoped) ||
          find_by_plaintext_token(token, unscoped)
      elsif migrating?
        find_by_plaintext_token(token, unscoped)
      else
        raise ArgumentError, 'Unknown encryption phase!'
      end
    end

    def ensure_token(instance)
      # TODO, tech debt, because some specs are testing migrations, but are still
      # using factory bot to create resources, it might happen that a database
      # schema does not have "#{token_name}_encrypted" field yet, however a bunch
      # of models call `ensure_#{token_name}` in `before_save`.
      #
      # In that case we are using insecure strategy, but this should only happen
      # in tests, because otherwise `encrypted_field` is going to exist.
      #
      # Another use case is when we are caching resources / columns, like we do
      # in case of ApplicationSetting.

      return super if instance.has_attribute?(encrypted_field)

      if fully_encrypted?
        raise ArgumentError, 'Using encrypted strategy when encrypted field is missing!'
      else
        insecure_strategy.ensure_token(instance)
      end
    end

    def get_token(instance)
      return insecure_strategy.get_token(instance) if migrating?

      encrypted_token = instance.read_attribute(encrypted_field)
      token = Gitlab::CryptoHelper.aes256_gcm_decrypt(encrypted_token)

      token || (insecure_strategy.get_token(instance) if fallback?)
    end

    def set_token(instance, token)
      raise ArgumentError unless token.present?

      instance[encrypted_field] = Gitlab::CryptoHelper.aes256_gcm_encrypt(token)
      instance[token_field] = token if migrating?
      instance[token_field] = nil if fallback?
      token
    end

    def fully_encrypted?
      !migrating? && !fallback?
    end

    protected

    def find_by_plaintext_token(token, unscoped)
      insecure_strategy.find_token_authenticatable(token, unscoped)
    end

    def find_by_encrypted_token(token, unscoped)
      encrypted_value = Gitlab::CryptoHelper.aes256_gcm_encrypt(token)
      relation(unscoped).find_by(encrypted_field => encrypted_value)
    end

    def insecure_strategy
      @insecure_strategy ||= TokenAuthenticatableStrategies::Insecure
        .new(klass, token_field, options)
    end

    def token_set?(instance)
      raw_token = instance.read_attribute(encrypted_field)

      unless fully_encrypted?
        raw_token ||= insecure_strategy.get_token(instance)
      end

      raw_token.present?
    end

    def encrypted_field
      @encrypted_field ||= "#{@token_field}_encrypted"
    end
  end
end
