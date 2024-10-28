# frozen_string_literal: true

module TokenAuthenticatableStrategies
  class Digest < Base
    def token_fields
      super + [token_field_name]
    end

    def find_token_authenticatable(token, unscoped = false)
      return unless token

      token_authenticatable = relation(unscoped).find_by(token_field_name => Gitlab::CryptoHelper.sha256(token))

      if @options[:fallback]
        token_authenticatable ||= fallback_strategy.find_token_authenticatable(token)
      end

      token_authenticatable
    end

    def get_token(token_owner_record)
      token = token_owner_record.cleartext_tokens&.[](@token_field)
      token ||= fallback_strategy.get_token(token_owner_record) if @options[:fallback]

      token
    end

    def set_token(token_owner_record, token)
      return unless token

      token_owner_record.cleartext_tokens ||= {}
      token_owner_record.cleartext_tokens[@token_field] = token
      token_owner_record[token_field_name] = Gitlab::CryptoHelper.sha256(token)
      token_owner_record[@token_field] = nil if @options[:fallback]
    end

    protected

    def fallback_strategy
      @fallback_strategy ||= TokenAuthenticatableStrategies::Insecure.new(@klass, @token_field, @options)
    end

    def token_set?(token_owner_record)
      token_digest = token_owner_record.read_attribute(token_field_name)
      token_digest ||= token_owner_record.read_attribute(@token_field) if @options[:fallback]

      token_digest.present?
    end

    def token_field_name
      "#{@token_field}_digest"
    end
  end
end
