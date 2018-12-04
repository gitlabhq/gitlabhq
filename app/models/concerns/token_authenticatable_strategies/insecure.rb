# frozen_string_literal: true

module TokenAuthenticatableStrategies
  class Insecure < Base
    def find_token_authenticatable(token, unscoped = false)
      relation(unscoped).find_by(@token_field => token) if token
    end

    def get_token(instance)
      instance.read_attribute(@token_field)
    end

    def set_token(instance, token)
      instance[@token_field] = token if token
    end

    protected

    def token_set?(instance)
      instance.read_attribute(@token_field).present?
    end
  end
end
