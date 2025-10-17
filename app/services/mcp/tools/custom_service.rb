# frozen_string_literal: true

# rubocop:disable Mcp/UseApiService -- Tool does not depend on REST API
module Mcp
  module Tools
    class CustomService < BaseService
      extend Gitlab::Utils::Override

      override :set_cred
      def set_cred(current_user: nil, access_token: nil)
        @current_user = current_user
        _ = access_token # access_token is not used in CustomService
      end

      def execute(request: nil, params: nil)
        return Response.error("CustomService: current_user is not set") unless current_user.present?

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

      # rubocop: disable CodeReuse/ActiveRecord -- no need to redefine a scope for the built-in method
      def find_project(project_id)
        raise ArgumentError, "Validation error: project_id must be a string" unless project_id.is_a?(String)

        projects = ::Project.without_deleted.not_hidden
        project =
          if ::API::Helpers::INTEGER_ID_REGEX.match?(project_id)
            projects.find_by(id: project_id)
          elsif project_id.include?('/')
            projects.find_by_full_path(project_id, follow_redirects: true)
          end

        raise StandardError, "Project '#{project_id}' not found or inaccessible" unless project

        project
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
# rubocop:enable Mcp/UseApiService
