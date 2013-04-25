module Gitlab
  module Git
    class Blame

      attr_accessor :repository, :sha, :path

      def initialize(repository, sha, path)
        @repository, @sha, @path = repository, sha, path
      end

      def each
        raw_blame = Grit::Blob.blame(repository.repo, sha, path)

        raw_blame.each do |commit, lines|
          next unless commit

          commit = Gitlab::Git::Commit.new(commit)
          yield(commit, lines)
        end
      end
    end
  end
end
