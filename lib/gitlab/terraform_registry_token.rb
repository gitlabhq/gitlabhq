# frozen_string_literal: true

module Gitlab
  class TerraformRegistryToken < JWTToken
    class << self
      def from_token(token)
        new.tap do |terraform_registry_token|
          terraform_registry_token['token'] = token.try(:token).presence || token.try(:id).presence
        end
      end
    end
  end
end
