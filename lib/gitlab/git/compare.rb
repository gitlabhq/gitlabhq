# Gitaly note: JV: no RPC's here.

module Gitlab
  module Git
    class Compare
      attr_reader :head, :base, :straight

      def initialize(repository, base, head, straight: false)
        @repository = repository
        @straight = straight
        @base = base
        @head = head

        unless base && head
          @commits = []
          return
        end

        @commits = [] unless @base && @head
        @commits = [] if same
      end

      def same
        @base && @head && @base == @head
      end

      def commits
        return @commits if defined?(@commits)

        @commits = Gitlab::Git::Commit.between(@repository, @base, @head)
      end

      def diffs(options = {})
        unless @head && @base
          return Gitlab::Git::DiffCollection.new([])
        end

        paths = options.delete(:paths) || []
        options[:straight] = @straight
        Gitlab::Git::Diff.between(@repository, @head, @base, options, *paths)
      end
    end
  end
end
