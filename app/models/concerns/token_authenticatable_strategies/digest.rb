# frozen_string_literal: true

module TokenAuthenticatableStrategies
  class Digest < Base
    def find_token_authenticatable(token, unscoped = false)
      return unless token

      token_authenticatable = relation(unscoped).find_by(token_field_name => Gitlab::CryptoHelper.sha256(token))

      if @options[:fallback]
        token_authenticatable ||= fallback_strategy.find_token_authenticatable(token)
      end

      token_authenticatable
    end

    def get_token(instance)
      token = instance.cleartext_tokens&.[](@token_field)
      token ||= fallback_strategy.get_token(instance) if @options[:fallback]

      token
    end

    def set_token(instance, token)
      return unless token

      instance.cleartext_tokens ||= {}
      instance.cleartext_tokens[@token_field] = token
      instance[token_field_name] = Gitlab::CryptoHelper.sha256(token)
      instance[@token_field] = nil if @options[:fallback]
    end

    protected

    def fallback_strategy
      @fallback_strategy ||= TokenAuthenticatableStrategies::Insecure.new(@klass, @token_field, @options)
    end

    def token_set?(instance)
      token_digest = instance.read_attribute(token_field_name)
      token_digest ||= instance.read_attribute(@token_field) if @options[:fallback]

      token_digest.present?
    end

    def token_field_name
      "#{@token_field}_digest"
    end
  end
end
