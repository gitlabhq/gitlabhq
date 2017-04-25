module Github
  module Representation
    class PullRequest < Representation::Issuable
      attr_reader :project

      delegate :user, :repo, :ref, :sha, to: :source_branch, prefix: true
      delegate :user, :exists?, :repo, :ref, :sha, :short_sha, to: :target_branch, prefix: true

      def source_project
        project
      end

      def source_branch_exists?
        !cross_project? && source_branch.exists?
      end

      def source_branch_name
        @source_branch_name ||=
          if cross_project? || !source_branch_exists?
            source_branch_name_prefixed
          else
            source_branch_ref
          end
      end

      def target_project
        project
      end

      def target_branch_name
        @target_branch_name ||= target_branch_exists? ? target_branch_ref : target_branch_name_prefixed
      end

      def state
        return 'merged' if raw['state'] == 'closed' && raw['merged_at'].present?
        return 'closed' if raw['state'] == 'closed'

        'opened'
      end

      def opened?
        state == 'opened'
      end

      def valid?
        source_branch.valid? && target_branch.valid?
      end

      private

      def project
        @project ||= options.fetch(:project)
      end

      def source_branch
        @source_branch ||= Representation::Branch.new(raw['head'], repository: project.repository)
      end

      def source_branch_name_prefixed
        "gh-#{target_branch_short_sha}/#{iid}/#{source_branch_user}/#{source_branch_ref}"
      end

      def target_branch
        @target_branch ||= Representation::Branch.new(raw['base'], repository: project.repository)
      end

      def target_branch_name_prefixed
        "gl-#{target_branch_short_sha}/#{iid}/#{target_branch_user}/#{target_branch_ref}"
      end

      def cross_project?
        return true if source_branch_repo.nil?

        source_branch_repo.id != target_branch_repo.id
      end
    end
  end
end
