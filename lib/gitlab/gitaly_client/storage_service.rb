module Gitlab
  module GitalyClient
    class StorageService
      def initialize(storage)
        @storage = storage
      end

      # Delete all repositories in the storage. This is a slow and VERY DESTRUCTIVE operation.
      def delete_all_repositories
        request = Gitaly::DeleteAllRepositoriesRequest.new(storage_name: @storage)
        GitalyClient.call(@storage, :storage_service, :delete_all_repositories, request)
      end
    end
  end
end
