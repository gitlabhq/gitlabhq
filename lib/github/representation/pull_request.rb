module Github
  module Representation
    class PullRequest < Representation::Issuable
      delegate :user, :repo, :ref, :sha, to: :source_branch, prefix: true
      delegate :user, :exists?, :repo, :ref, :sha, :short_sha, to: :target_branch, prefix: true

      def source_project
        project
      end

      def source_branch_name
        # Mimic the "user:branch" displayed in the MR widget,
        # i.e. "Request to merge rymai:add-external-mounts into master"
        cross_project? ? "#{source_branch_user}:#{source_branch_ref}" : source_branch_ref
      end

      def target_project
        project
      end

      def target_branch_name
        target_branch_ref
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

      def assigned?
        raw['assignee'].present?
      end

      def assignee
        return unless assigned?

        @assignee ||= Github::Representation::User.new(raw['assignee'], options)
      end

      private

      def project
        @project ||= options.fetch(:project)
      end

      def source_branch
        @source_branch ||= Representation::Branch.new(raw['head'], repository: project.repository)
      end

      def target_branch
        @target_branch ||= Representation::Branch.new(raw['base'], repository: project.repository)
      end

      def cross_project?
        return true if source_branch_repo.nil?

        source_branch_repo.id != target_branch_repo.id
      end
    end
  end
end
