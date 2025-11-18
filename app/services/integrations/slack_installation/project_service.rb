# frozen_string_literal: true

module Integrations
  module SlackInstallation
    class ProjectService < BaseService
      def initialize(project, current_user:, params:)
        @project = project

        super(current_user: current_user, params: params)
      end

      private

      attr_reader :project

      def redirect_uri
        slack_auth_project_settings_slack_url(project)
      end

      def installation_alias
        project.full_path
      end

      # Returns a fallback alias for the project when the default alias (full_path) is already taken.
      def fallback_alias
        "#{project.full_path}/p-#{project.id}"
      end

      def authorized?
        current_user.can?(:admin_project, project)
      end

      def find_or_create_integration!
        project.gitlab_slack_application_integration || project.create_gitlab_slack_application_integration!
      end
    end
  end
end
