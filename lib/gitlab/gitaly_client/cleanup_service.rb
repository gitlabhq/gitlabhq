# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class CleanupService
      include Gitlab::EncodingHelper
      include WithFeatureFlagActors

      attr_reader :repository, :gitaly_repo, :storage

      # 'repository' is a Gitlab::Git::Repository
      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage

        self.repository_actor = repository
      end

      def apply_bfg_object_map_stream(io, &blk)
        response = gitaly_client_call(
          storage,
          :cleanup_service,
          :apply_bfg_object_map_stream,
          build_object_map_enum(io),
          timeout: GitalyClient.long_timeout
        )
        response.each(&blk)
      end

      def rewrite_history(blobs: [], redactions: [])
        req_enum = Enumerator.new do |y|
          first_request = Gitaly::RewriteHistoryRequest.new(repository: @gitaly_repo)
          y.yield(first_request)

          blobs.each_slice(100) do |b|
            y.yield Gitaly::RewriteHistoryRequest.new(blobs: b)
          end

          redactions.map { |r| encode_binary(r) }.each_slice(100) do |r|
            y.yield Gitaly::RewriteHistoryRequest.new(redactions: r)
          end
        end

        gitaly_client_call(@repository.storage, :cleanup_service, :rewrite_history, req_enum,
          timeout: GitalyClient.long_timeout)
      rescue GRPC::InvalidArgument => e
        raise ArgumentError, e.message
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
