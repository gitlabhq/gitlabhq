module Gitlab
  module GitalyClient
    class StorageService
      def initialize(storage)
        @storage = storage
      end

      # Returns all directories in the git storage directory, lexically ordered
      def list_directories(depth: 1)
        request = Gitaly::ListDirectoriesRequest.new(storage_name: @storage, depth: depth)

        GitalyClient.call(@storage, :storage_service, :list_directories, request)
          .flat_map(&:paths)
      end

      # Delete all repositories in the storage. This is a slow and VERY DESTRUCTIVE operation.
      def delete_all_repositories
        request = Gitaly::DeleteAllRepositoriesRequest.new(storage_name: @storage)
        GitalyClient.call(@storage, :storage_service, :delete_all_repositories, request)
      end
    end
  end
end
