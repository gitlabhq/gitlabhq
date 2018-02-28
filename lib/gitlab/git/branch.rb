# Gitaly note: JV: no RPC's here.

module Gitlab
  module Git
    class Branch < Ref
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
    end
  end
end
