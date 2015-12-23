module Gitlab
  module GithubImport
    class PullRequest
      attr_reader :project, :raw_data

      def initialize(project, raw_data)
        @project = project
        @raw_data = raw_data
        @formatter = Gitlab::ImportFormatter.new
      end

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

      def valid?
        source_branch.present? && target_branch.present?
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

      def source_project
        project
      end

      def source_branch
        source_project.repository.find_branch(raw_data.head.ref)
      end

      def target_project
        project
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

      def gl_user_id(github_id)
        User.joins(:identities).
          find_by("identities.extern_uid = ? AND identities.provider = 'github'", github_id.to_s).
          try(:id)
      end
    end
  end
end
