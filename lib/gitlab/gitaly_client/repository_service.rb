module Gitlab
  module GitalyClient
    class RepositoryService
      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage
      end

      def exists?
        request = Gitaly::RepositoryExistsRequest.new(repository: @gitaly_repo)

        GitalyClient.call(@storage, :repository_service, :repository_exists, request).exists
      end

      def garbage_collect(create_bitmap)
        request = Gitaly::GarbageCollectRequest.new(repository: @gitaly_repo, create_bitmap: create_bitmap)
        GitalyClient.call(@storage, :repository_service, :garbage_collect, request)
      end

      def repack_full(create_bitmap)
        request = Gitaly::RepackFullRequest.new(repository: @gitaly_repo, create_bitmap: create_bitmap)
        GitalyClient.call(@storage, :repository_service, :repack_full, request)
      end

      def repack_incremental
        request = Gitaly::RepackIncrementalRequest.new(repository: @gitaly_repo)
        GitalyClient.call(@storage, :repository_service, :repack_incremental, request)
      end

      def repository_size
        request = Gitaly::RepositorySizeRequest.new(repository: @gitaly_repo)
        GitalyClient.call(@storage, :repository_service, :repository_size, request).size
      end

      def apply_gitattributes(revision)
        request = Gitaly::ApplyGitattributesRequest.new(repository: @gitaly_repo, revision: revision)
        GitalyClient.call(@storage, :repository_service, :apply_gitattributes, request)
      end
    end
  end
end
