# frozen_string_literal: true

module Gitlab
  module Git
    class RepositoryCleaner
      include Gitlab::Git::WrapsGitalyErrors

      attr_reader :repository

      # 'repository' is a Gitlab::Git::Repository
      def initialize(repository)
        @repository = repository
      end

      def apply_bfg_object_map_stream(io, &blk)
        wrapped_gitaly_errors do
          gitaly_cleanup_client.apply_bfg_object_map_stream(io, &blk)
        end
      end

      def rewrite_history(blobs: [], redactions: [])
        wrapped_gitaly_errors do
          gitaly_cleanup_client.rewrite_history(blobs: blobs, redactions: redactions)
        end
      end

      private

      def gitaly_cleanup_client
        @gitaly_cleanup_client ||= Gitlab::GitalyClient::CleanupService.new(repository)
      end
    end
  end
end
