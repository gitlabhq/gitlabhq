# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class CleanupService
      attr_reader :repository, :gitaly_repo, :storage

      # 'repository' is a Gitlab::Git::Repository
      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage
      end

      def apply_bfg_object_map(io)
        first_request = Gitaly::ApplyBfgObjectMapRequest.new(repository: gitaly_repo)

        enum = Enumerator.new do |y|
          y.yield first_request

          while data = io.read(RepositoryService::MAX_MSG_SIZE)
            y.yield Gitaly::ApplyBfgObjectMapRequest.new(object_map: data)
            break if io&.eof?
          end
        end

        GitalyClient.call(
          storage,
          :cleanup_service,
          :apply_bfg_object_map,
          enum,
          timeout: GitalyClient.no_timeout
        )
      end
    end
  end
end
