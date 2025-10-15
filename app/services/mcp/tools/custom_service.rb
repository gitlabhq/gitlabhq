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
        if current_user.present?
          super
        else
          Response.error("CustomService: current_user is not set")
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord -- no need to redefine a scope for the built in method
      def find_project(project_id)
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
