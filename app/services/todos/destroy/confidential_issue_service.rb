# frozen_string_literal: true

module Todos
  module Destroy
    # Service class for deleting todos that belongs to confidential issues.
    # It deletes todos for users that are not at least planners, issue author or assignee.
    #
    # Accepts issue_id or project_id as argument.
    # When issue_id is passed it deletes matching todos for one confidential issue.
    # When project_id is passed it deletes matching todos for all confidential issues of the project.
    class ConfidentialIssueService < ::Todos::Destroy::BaseService
      attr_reader :issues

      def initialize(issue_id: nil, project_id: nil)
        @issues =
          if issue_id
            Issue.id_in(issue_id)
          elsif project_id
            project_confidential_issues(project_id)
          end
      end

      def execute
        return unless todos_to_remove?

        ::Gitlab::Database.allow_cross_joins_across_databases(
          url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/422045') do
          delete_todos
        end
      end

      private

      def delete_todos
        authorized_users = ProjectAuthorization.select(:user_id)
          .for_project(project_ids)
          .non_guests

        todos.not_in_users(authorized_users).delete_all
      end

      def project_confidential_issues(project_id)
        project = Project.find(project_id)

        project.issues.confidential_only
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def todos
        Todo.joins_issue_and_assignees
          .for_target(issues)
          .merge(Issue.confidential_only)
          .where('todos.user_id != issues.author_id')
          .where('todos.user_id != issue_assignees.user_id')
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def todos_to_remove?
        issues&.any?(&:confidential?)
      end

      def project_ids
        issues&.distinct&.select(:project_id)
      end
    end
  end
end
