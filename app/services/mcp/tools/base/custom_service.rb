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
          raise ArgumentError, "#{name}: target object not found, the params received: #{params.inspect}" if target.nil?

          allowed = ::Ability.allowed?(current_user, auth_ability, target)
          return if allowed

          raise Gitlab::Access::AccessDeniedError, "CustomService: User #{current_user.id} does " \
            "not have permission to #{auth_ability} for target #{target.id}"
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
