module Gitlab
  module Git
    class Branch < Ref
      class << self
        def find(repo, branch_name)
          if branch_name.is_a?(Gitlab::Git::Branch)
            branch_name
          else
            repo.find_branch(branch_name)
          end
        end

        def names_contains_sha(repo, sha, limit: 0)
          GitalyClient::RefService.new(repo).branch_names_contains_sha(sha)
        end
      end

      def initialize(repository, name, target, target_commit)
        super(repository, name, target, target_commit)
      end
    end
  end
end
