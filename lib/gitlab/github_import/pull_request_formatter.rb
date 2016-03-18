module Gitlab
  module GithubImport
    class PullRequestFormatter < BaseFormatter
      def attributes
        {
          title: raw_data.title,
          description: description,
          source_project: source_project,
          source_branch: source_branch.name,
          target_project: target_project,
          target_branch: target_branch.name,
          state: state,
          author_id: author_id,
          assignee_id: assignee_id,
          created_at: raw_data.created_at,
          updated_at: updated_at
        }
      end

      def number
        raw_data.number
      end

      def valid?
        !cross_project? && source_branch.present? && target_branch.present?
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

      def cross_project?
        source_repo.present? && target_repo.present? && source_repo.id != target_repo.id
      end

      def description
        formatter.author_line(author) + body
      end

      def source_project
        project
      end

      def source_repo
        raw_data.head.repo
      end

      def source_branch
        source_project.repository.find_branch(raw_data.head.ref)
      end

      def target_project
        project
      end

      def target_repo
        raw_data.base.repo
      end

      def target_branch
        target_project.repository.find_branch(raw_data.base.ref)
      end

      def state
        @state ||= case true
                   when raw_data.state == 'closed' && raw_data.merged_at.present?
                     'merged'
                   when raw_data.state == 'closed'
                     'closed'
                   else
                     'opened'
                   end
      end

      def updated_at
        case state
        when 'merged' then raw_data.merged_at
        when 'closed' then raw_data.closed_at
        else
          raw_data.updated_at
        end
      end
    end
  end
end
