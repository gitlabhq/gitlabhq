# frozen_string_literal: true

module Gitlab
  module JiraImport
    class UserMapper
      include ::Gitlab::Utils::StrongMemoize

      def initialize(project, jira_user)
        @project = project
        @jira_user = jira_user
      end

      def execute
        return unless jira_user

        email = jira_user['emailAddress']

        # We also include emails that are not yet confirmed
        users = User.by_any_email(email).to_a

        user = users.first

        # this event should never happen but we should log it in case we have invalid data
        log_user_mapping_message('Multiple users found for an email address', email) if users.count > 1

        unless project.project_member(user) || project.group&.group_member(user)
          log_user_mapping_message('Jira user not found', email)

          return
        end

        user
      end

      private

      attr_reader :project, :jira_user, :params

      def log_user_mapping_message(message, email)
        logger.info(
          project_id: project.id,
          project_path: project.full_path,
          user_email: email,
          message: message
        )
      end

      def logger
        @logger ||= Gitlab::Import::Logger.build
      end
    end
  end
end
