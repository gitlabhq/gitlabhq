module Gitlab
  module LegacyGithubImport
    class IssueFormatter < IssuableFormatter
      def attributes
        {
          iid: number,
          project: project,
          milestone: milestone,
          title: raw_data.title,
          description: description,
          state: state,
          author_id: author_id,
          assignee_ids: Array(assignee_id),
          created_at: raw_data.created_at,
          updated_at: raw_data.updated_at
        }
      end

      def has_comments?
        raw_data.comments > 0
      end

      def project_association
        :issues
      end

      def pull_request?
        raw_data.pull_request.present?
      end
    end
  end
end
