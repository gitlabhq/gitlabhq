module Gitlab
  module GitalyClient
    class RepositoryService
      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
      end

      def exists?
        request = Gitaly::RepositoryExistsRequest.new(repository: @gitaly_repo)

        GitalyClient.call(@repository.storage, :repository_service, :exists, request).exists
      end
    end
  end
end
