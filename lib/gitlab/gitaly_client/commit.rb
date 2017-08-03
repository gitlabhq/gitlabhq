module Gitlab
  module GitalyClient
    class Commit
      attr_reader :repository, :gitaly_commit

      delegate :id, :subject, :body, :author, :committer, :parent_ids, to: :gitaly_commit

      def initialize(repository, gitaly_commit)
        @repository = repository
        @gitaly_commit = gitaly_commit
      end
    end
  end
end
