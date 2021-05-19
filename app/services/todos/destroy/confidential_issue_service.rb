# frozen_string_literal: true

module Todos
  module Destroy
    # Service class for deleting todos that belongs to confidential issues.
    # It deletes todos for users that are not at least reporters, issue author or assignee.
    #
    # Accepts issue_id or project_id as argument.
    # When issue_id is passed it deletes matching todos for one confidential issue.
    # When project_id is passed it deletes matching todos for all confidential issues of the project.
    class ConfidentialIssueService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      attr_reader :issues

      # rubocop: disable CodeReuse/ActiveRecord
      def initialize(issue_id: nil, project_id: nil)
        @issues =
          if issue_id
            Issue.where(id: issue_id)
          elsif project_id
            project_confidential_issues(project_id)
          end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def project_confidential_issues(project_id)
        project = Project.find(project_id)

        project.issues.confidential_only
      end

      override :todos
      # rubocop: disable CodeReuse/ActiveRecord
      def todos
        Todo.joins_issue_and_assignees
          .where(target: issues)
          .where(issues: { confidential: true })
          .where('todos.user_id != issues.author_id')
          .where('todos.user_id != issue_assignees.user_id')
      end
      # rubocop: enable CodeReuse/ActiveRecord

      override :todos_to_remove?
      def todos_to_remove?
        issues&.any?(&:confidential?)
      end

      override :project_ids
      def project_ids
        issues&.distinct&.select(:project_id)
      end

      override :authorized_users
      # rubocop: disable CodeReuse/ActiveRecord
      def authorized_users
        ProjectAuthorization.select(:user_id)
          .where(project_id: project_ids)
          .where('access_level >= ?', Gitlab::Access::REPORTER)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
