# frozen_string_literal: true

module TokenAuthenticatableStrategies
  class Digest < Base
    def token_fields
      super + [token_field_name]
    end

    def find_token_authenticatable(token, unscoped = false)
      return unless token

      relation(unscoped).find_by(token_field_name => Gitlab::CryptoHelper.sha256(token))
    end

    def get_token(token_owner_record)
      token_owner_record.cleartext_tokens&.[](token_field)
    end

    def set_token(token_owner_record, token)
      return unless token

      token_owner_record.cleartext_tokens ||= {}
      token_owner_record.cleartext_tokens[token_field] = token
      token_owner_record[token_field_name] = Gitlab::CryptoHelper.sha256(token)
    end

    protected

    def token_set?(token_owner_record)
      token_owner_record.read_attribute(token_field_name).present?
    end

    def token_field_name
      "#{token_field}_digest"
    end
  end
end
