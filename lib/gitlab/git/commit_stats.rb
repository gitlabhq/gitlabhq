# Gitaly note: JV: 1 RPC, migration in progress.

# Gitlab::Git::CommitStats counts the additions, deletions, and total changes
# in a commit.
module Gitlab
  module Git
    class CommitStats
      attr_reader :id, :additions, :deletions, :total

      # Instantiate a CommitStats object
      #
      # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/323
      def initialize(commit)
        @id = commit.id
        @additions = 0
        @deletions = 0
        @total = 0

        diff = commit.diff_from_parent

        diff.each_patch do |p|
          # TODO: Use the new Rugged convenience methods when they're released
          @additions += p.stat[0]
          @deletions += p.stat[1]
          @total += p.changes
        end
      end
    end
  end
end
