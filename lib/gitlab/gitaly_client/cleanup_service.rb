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

      def apply_bfg_object_map_stream(io, &blk)
        responses = GitalyClient.call(
          storage,
          :cleanup_service,
          :apply_bfg_object_map_stream,
          build_object_map_enum(io),
          timeout: GitalyClient.no_timeout
        )

        responses.each(&blk)
      end

      private

      def build_object_map_enum(io)
        Enumerator.new do |y|
          # First request. For simplicity, doesn't include any object map data
          y << Gitaly::ApplyBfgObjectMapStreamRequest.new(repository: gitaly_repo)

          # Now stream the BFG object map file to gitaly in chunks
          while data = io.read(RepositoryService::MAX_MSG_SIZE)
            y << Gitaly::ApplyBfgObjectMapStreamRequest.new(object_map: data)

            break if io&.eof?
          end
        end
      end
    end
  end
end
