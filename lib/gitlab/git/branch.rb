# frozen_string_literal: true

module Gitlab
  module Git
    class Branch < Ref
      STALE_BRANCH_THRESHOLD = 3.months

      def self.find(repo, branch_name)
        if branch_name.is_a?(Gitlab::Git::Branch)
          branch_name
        else
          repo.find_branch(branch_name)
        end
      end

      def initialize(repository, name, target, target_commit)
        super(repository, name, target, target_commit)
      end

      def active?
        self.dereferenced_target.committed_date >= STALE_BRANCH_THRESHOLD.ago
      end

      def stale?
        !active?
      end

      def state
        active? ? :active : :stale
      end

      def cache_key
        "branch:" + Digest::SHA1.hexdigest([name, target, dereferenced_target&.sha].join(':'))
      end
    end
  end
end
