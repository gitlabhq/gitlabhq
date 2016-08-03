module Gitlab
  module GithubImport
    class PullRequestFormatter < BaseFormatter
      delegate :exists?, :name, :project, :repo, :sha, to: :source_branch, prefix: true
      delegate :exists?, :name, :project, :repo, :sha, to: :target_branch, prefix: true

      def attributes
        {
          iid: number,
          title: raw_data.title,
          description: description,
          source_project: source_branch_project,
          source_branch: source_branch_name,
          source_branch_sha: source_branch_sha,
          target_project: target_branch_project,
          target_branch: target_branch_name,
          target_branch_sha: target_branch_sha,
          state: state,
          milestone: milestone,
          author_id: author_id,
          assignee_id: assignee_id,
          created_at: raw_data.created_at,
          updated_at: updated_at
        }
      end

      def klass
        MergeRequest
      end

      def number
        raw_data.number
      end

      def valid?
        source_branch.valid? && target_branch.valid?
      end

      def source_branch
        @source_branch ||= BranchFormatter.new(project, raw_data.head)
      end

      def target_branch
        @target_branch ||= BranchFormatter.new(project, raw_data.base)
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
        formatter.author_line(author) + body
      end

      def milestone
        if raw_data.milestone.present?
          project.milestones.find_by(iid: raw_data.milestone.number)
        end
      end

      def state
        @state ||= if raw_data.state == 'closed' && raw_data.merged_at.present?
                     'merged'
                   elsif raw_data.state == 'closed'
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
