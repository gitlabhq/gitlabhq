# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class PraefectInfoService
      include WithFeatureFlagActors

      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage

        self.repository_actor = repository
      end

      def replicas
        request = Gitaly::RepositoryReplicasRequest.new(repository: @gitaly_repo)

        gitaly_client_call(@storage, :praefect_info_service, :repository_replicas, request, timeout: GitalyClient.fast_timeout)
      end
    end
  end
end
