# frozen_string_literal: true

# rubocop:disable Mcp/UseApiService -- Tool does not depend on REST API
module Mcp
  module Tools
    module Base
      class CustomService < BaseService
        include Mcp::Tools::Concerns::Versionable
        include ::Mcp::Tools::Concerns::ResourceFinder
        extend ::Gitlab::Utils::Override

        def initialize(name:, version: nil)
          super(name: name)
          initialize_version(version)
        end

        override :set_cred
        def set_cred(current_user: nil, access_token: nil)
          @current_user = current_user
          _ = access_token # access_token is not used in CustomService
        end

        def execute(request: nil, params: nil)
          return Response.error("#{self.class.name}: current_user is not set") unless current_user.present?

          authorize!(params)

          super
        rescue StandardError => e
          Response.error("Tool execution failed: #{e.message}")
        end

        def authorize!(params)
          target = auth_target(params)
          return if target && ::Ability.allowed?(current_user, auth_ability, target)

          raise ArgumentError, authorization_error_message
        end

        def authorization_error_message
          "#{name}: not found or access denied"
        end

        def auth_ability
          raise NoMethodError, "#{self.class.name}#auth_ability should be implemented in a subclass"
        end

        def auth_target(_params)
          raise NoMethodError, "#{self.class.name}#auth_target should be implemented in a subclass"
        end
      end
    end
  end
end
# rubocop:enable Mcp/UseApiService
