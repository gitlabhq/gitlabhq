# frozen_string_literal: true

module Gitlab
  module PoolRepositories
    class DiscoveryService
      def initialize(logger, verbose)
        @logger = logger
        @verbose = verbose
        # rubocop:disable CodeReuse/ActiveRecord -- Pre-loading pool disk paths for discovery
        @pool_disk_paths_cache = Set.new(PoolRepository.pluck(:disk_path))
        # rubocop:enable CodeReuse/ActiveRecord
      end

      def pool_disk_path_exists?(disk_path)
        @pool_disk_paths_cache.include?(disk_path)
      end

      def scan_pool_metadata(storage_name)
        request = Gitaly::ScanPoolMetadataRequest.new(storage_name: storage_name)

        response = Gitlab::GitalyClient.call(
          storage_name,
          :object_pool_service,
          :scan_pool_metadata,
          request,
          timeout: Gitlab::GitalyClient.long_timeout
        )

        response.map do |entry|
          {
            relative_path: entry.relative_path,
            pool_disk_path: entry.pool_disk_path.presence
          }
        end
      rescue StandardError => e
        @logger.debug "Failed to scan pool metadata on storage #{storage_name}: #{e.message}" if @verbose
        []
      end
    end
  end
end
