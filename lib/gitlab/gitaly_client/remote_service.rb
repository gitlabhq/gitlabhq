module Gitlab
  module GitalyClient
    class RemoteService
      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage
      end

      def add_remote(name, url, mirror_refmap)
        request = Gitaly::AddRemoteRequest.new(
          repository: @gitaly_repo, name: name, url: url,
          mirror_refmap: mirror_refmap.to_s
        )

        GitalyClient.call(@storage, :remote_service, :add_remote, request)
      end

      def remove_remote(name)
        request = Gitaly::RemoveRemoteRequest.new(repository: @gitaly_repo, name: name)

        response = GitalyClient.call(@storage, :remote_service, :remove_remote, request)

        response.result
      end

      def fetch_internal_remote(repository)
        request = Gitaly::FetchInternalRemoteRequest.new(
          repository: @gitaly_repo,
          remote_repository: repository.gitaly_repository
        )

        response = GitalyClient.call(@storage, :remote_service,
                                     :fetch_internal_remote, request,
                                     remote_storage: repository.storage)

        response.result
      end
    end
  end
end
