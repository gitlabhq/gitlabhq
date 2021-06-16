# frozen_string_literal: true

module Gitlab
  module Git
    #
    # When a Gitaly call involves two repositories instead of one we cannot
    # assume that both repositories are on the same Gitaly server. In this
    # case we need to make a distinction between the repository that the
    # call is being made on (a Repository instance), and the "other"
    # repository (a RemoteRepository instance). This is the reason why we
    # have the RemoteRepository class in Gitlab::Git.
    #
    # When you make changes, be aware that gitaly-ruby sub-classes this
    # class.
    #
    class RemoteRepository
      attr_reader :relative_path, :gitaly_repository

      def initialize(repository)
        @relative_path = repository.relative_path
        @gitaly_repository = repository.gitaly_repository

        # These instance variables will not be available in gitaly-ruby, where
        # we have no disk access to this repository.
        @repository = repository
      end

      def empty?
        # We will override this implementation in gitaly-ruby because we cannot
        # use '@repository' there.
        #
        # Caches and memoization used on the Rails side
        !@repository.exists? || @repository.empty?
      end

      def commit_id(revision)
        # We will override this implementation in gitaly-ruby because we cannot
        # use '@repository' there.
        @repository.commit(revision)&.sha
      end

      def branch_exists?(name)
        # We will override this implementation in gitaly-ruby because we cannot
        # use '@repository' there.
        @repository.branch_exists?(name)
      end

      # Compares self to a Gitlab::Git::Repository. This implementation uses
      # 'self.gitaly_repository' so that it will also work in the
      # GitalyRemoteRepository subclass defined in gitaly-ruby.
      def same_repository?(other_repository)
        gitaly_repository.storage_name == other_repository.storage &&
          gitaly_repository.relative_path == other_repository.relative_path
      end

      def path
        @repository.path
      end

      private

      # Must return an object that responds to 'address' and 'storage'.
      def gitaly_client
        Gitlab::GitalyClient
      end

      def storage
        gitaly_repository.storage_name
      end
    end
  end
end
