module Gitlab
  module GithubImport
    class IssueFormatter < BaseFormatter
      def attributes
        {
          iid: number,
          project: project,
          milestone: milestone,
          title: raw_data.title,
          description: description,
          state: state,
          author_id: author_id,
          assignee_id: assignee_id,
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

      def find_condition
        { iid: number }
      end

      def number
        raw_data.number
      end

      def pull_request?
        raw_data.pull_request.present?
      end

      private

      def assigned?
        raw_data.assignee.present?
      end

      def assignee_id
        if assigned?
          gitlab_user_id(raw_data.assignee.id)
        end
      end

      def author
        raw_data.user.login
      end

      def author_id
        gitlab_author_id || project.creator_id
      end

      def body
        raw_data.body || ""
      end

      def description
        if gitlab_author_id
          body
        else
          formatter.author_line(author) + body
        end
      end

      def milestone
        if raw_data.milestone.present?
          project.milestones.find_by(iid: raw_data.milestone.number)
        end
      end

      def state
        raw_data.state == 'closed' ? 'closed' : 'opened'
      end
    end
  end
end
