# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class IssueFormatter < IssuableFormatter
      def attributes
        {
          iid: number,
          project: project,
          milestone: milestone,
          title: raw_data[:title],
          description: description,
          state: state,
          author_id: author_id,
          assignee_ids: Array(assignee_id),
          created_at: raw_data[:created_at],
          updated_at: raw_data[:updated_at],
          imported_from: imported_from
        }
      end

      def has_comments?
        raw_data[:comments] > 0
      end

      def project_association
        :issues
      end

      def pull_request?
        raw_data[:pull_request].present?
      end

      def project_assignee_association
        :issue_assignees
      end

      def contributing_user_formatters
        {
          author_id: author
        }
      end

      def contributing_assignee_formatters
        {
          user_id: assignee
        }
      end
    end
  end
end
