# frozen_string_literal: true

module TokenAuthenticatableStrategies
  class Insecure < Base
    def find_token_authenticatable(token, unscoped = false)
      relation(unscoped).find_by(@token_field => token) if token
    end

    def get_token(token_owner_record)
      token_owner_record.read_attribute(@token_field)
    end

    def set_token(token_owner_record, token)
      token_owner_record[@token_field] = token if token
    end

    protected

    def token_set?(token_owner_record)
      token_owner_record.read_attribute(@token_field).present?
    end
  end
end
