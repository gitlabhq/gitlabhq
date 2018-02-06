module Gitlab
  module LegacyGithubImport
    class PullRequestFormatter < IssuableFormatter
      delegate :user, :project, :ref, :repo, :sha, to: :source_branch, prefix: true
      delegate :user, :exists?, :project, :ref, :repo, :sha, :short_sha, to: :target_branch, prefix: true

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
          updated_at: raw_data.updated_at,
          imported: true
        }
      end

      def project_association
        :merge_requests
      end

      def valid?
        source_branch.valid? && target_branch.valid?
      end

      def source_branch
        @source_branch ||= BranchFormatter.new(project, raw_data.head)
      end

      def source_branch_name
        @source_branch_name ||=
          if cross_project? || !source_branch_exists?
            source_branch_name_prefixed
          else
            source_branch_ref
          end
      end

      def source_branch_name_prefixed
        "gh-#{target_branch_short_sha}/#{number}/#{source_branch_user}/#{source_branch_ref}"
      end

      def source_branch_exists?
        !cross_project? && source_branch.exists?
      end

      def target_branch
        @target_branch ||= BranchFormatter.new(project, raw_data.base)
      end

      def target_branch_name
        @target_branch_name ||= target_branch_exists? ? target_branch_ref : target_branch_name_prefixed
      end

      def target_branch_name_prefixed
        "gl-#{target_branch_short_sha}/#{number}/#{target_branch_user}/#{target_branch_ref}"
      end

      def cross_project?
        return true if source_branch_repo.nil?

        source_branch_repo.id != target_branch_repo.id
      end

      def opened?
        state == 'opened'
      end

      private

      def state
        if raw_data.state == 'closed' && raw_data.merged_at.present?
          'merged'
        else
          super
        end
      end
    end
  end
end
