# frozen_string_literal: true

module Todos
  module Destroy
    class ConfidentialIssueService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      attr_reader :issue

      def initialize(issue_id)
        @issue = Issue.find_by(id: issue_id)
      end

      private

      override :todos
      def todos
        Todo.where(target: issue)
          .where('user_id != ?', issue.author_id)
          .where('user_id NOT IN (?)', issue.assignees.select(:id))
      end

      override :todos_to_remove?
      def todos_to_remove?
        issue&.confidential?
      end

      override :project_ids
      def project_ids
        issue.project_id
      end

      override :authorized_users
      def authorized_users
        ProjectAuthorization.select(:user_id)
          .where(project_id: project_ids)
          .where('access_level >= ?', Gitlab::Access::REPORTER)
      end
    end
  end
end
