# frozen_string_literal: true

module Todos
  module Destroy
    class ConfidentialIssueService < ::Todos::Destroy::BaseService
      extend ::Gitlab::Utils::Override

      attr_reader :issue

      # rubocop: disable CodeReuse/ActiveRecord
      def initialize(issue_id)
        @issue = Issue.find_by(id: issue_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      override :todos
      # rubocop: disable CodeReuse/ActiveRecord
      def todos
        Todo.where(target: issue)
          .where('user_id != ?', issue.author_id)
          .where('user_id NOT IN (?)', issue.assignees.select(:id))
      end
      # rubocop: enable CodeReuse/ActiveRecord

      override :todos_to_remove?
      def todos_to_remove?
        issue&.confidential?
      end

      override :project_ids
      def project_ids
        issue.project_id
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
