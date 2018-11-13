# frozen_string_literal: true

          @parallelizable.with_indifferent_access

module TokenAuthenticatableStrategies
  class Encrypted < Base
    def find_token_authenticatable(token, unscoped = false)
      return unless token

      token_authenticatable = relation(unscoped)
        .find_by(token_field_name => Gitlab::CryptoHelper.aes256_gcm_encrypt(token))

      if @options[:fallback]
        token_authenticatable ||= fallback_strategy.find_token_authenticatable(token)
      end

      token_authenticatable
    end

    def get_token(instance)
      raw_token = instance.read_attribute(token_field_name)
      token = Gitlab::CryptoHelper.aes256_gcm_decrypt(raw_token)
      token ||= fallback_strategy.get_token(instance) if @options[:fallback]
    end

    def set_token(instance, token)
      raise ArgumentError unless token

      instance[token_field_name] = Gitlab::CryptoHelper.aes256_gcm_encrypt(token)
      # instance[@token_field] = nil if @options[:fallback] # TODO this seems wrong
    end

    protected

    def fallback_strategy
      @fallback_strategy ||= TokenAuthenticatableStrategies::Insecure
        .new(@klass, @token_field, @options)
    end

    def token_set?(instance)
      token_digest = instance.read_attribute(token_field_name)
      token_digest ||= instance.read_attribute(@token_field) if @options[:fallback]

      token_digest.present?
    end

    def token_field_name
      "#{@token_field}_encrypted"
    end
  end
end
