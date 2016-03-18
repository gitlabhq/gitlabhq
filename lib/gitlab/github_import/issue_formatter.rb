module Gitlab
  module GithubImport
    class IssueFormatter < BaseFormatter
      def attributes
        {
          project: project,
          title: raw_data.title,
          description: description,
          state: state,
          author_id: author_id,
          assignee_id: assignee_id,
          created_at: raw_data.created_at,
          updated_at: updated_at
        }
      end

      def has_comments?
        raw_data.comments > 0
      end

      def number
        raw_data.number
      end

      def valid?
        raw_data.pull_request.nil?
      end

      private

      def assigned?
        raw_data.assignee.present?
      end

      def assignee_id
        if assigned?
          gl_user_id(raw_data.assignee.id)
        end
      end

      def author
        raw_data.user.login
      end

      def author_id
        gl_user_id(raw_data.user.id) || project.creator_id
      end

      def body
        raw_data.body || ""
      end

      def description
        @formatter.author_line(author) + body
      end

      def state
        raw_data.state == 'closed' ? 'closed' : 'opened'
      end

      def updated_at
        state == 'closed' ? raw_data.closed_at : raw_data.updated_at
      end
    end
  end
end
