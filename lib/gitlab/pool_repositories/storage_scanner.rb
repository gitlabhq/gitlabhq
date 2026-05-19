# frozen_string_literal: true

module Gitlab
  module PoolRepositories
    class StorageScanner
      attr_reader :orphaned_pools

      def initialize(logger, verbose, discovery_service, csv_writer)
        @logger = logger
        @verbose = verbose
        @orphaned_pools = []
        @discovery_service = discovery_service
        @csv_writer = csv_writer
        @seen_disk_paths = Set.new
      end

      def scan_all_storages
        storages = Gitlab.config.repositories.storages.keys

        storages.each do |storage_name|
          scan_storage(storage_name)
        rescue StandardError => e
          @logger.error "Error scanning storage #{storage_name}: #{e.message}"
          @logger.debug e.backtrace.join("\n") if @verbose
        end
      end

      private

      def scan_storage(storage_name)
        @logger.info "Scanning storage '#{storage_name}' for pools..."

        pool_metadata = @discovery_service.scan_pool_metadata(storage_name)
        check_pools_for_orphans(storage_name, pool_metadata)
      end

      def check_pools_for_orphans(storage_name, pool_metadata)
        pool_metadata.each do |entry|
          pool_disk_path = entry[:pool_disk_path]
          next if pool_disk_path.blank?

          disk_path = pool_disk_path.chomp('.git')
          next if @discovery_service.pool_disk_path_exists?(disk_path)

          log_gitaly_orphan(disk_path, storage_name)
        end
      rescue StandardError => e
        @logger.error "Error checking pools on storage #{storage_name}: #{e.message}"
        @logger.debug e.backtrace.join("\n") if @verbose
      end

      def log_gitaly_orphan(pool_disk_path, storage_name)
        return if @seen_disk_paths.include?(pool_disk_path)

        orphan_record = OrphanRecord.from_gitaly(pool_disk_path, storage_name)

        @seen_disk_paths.add(pool_disk_path)

        @orphaned_pools << orphan_record
        @csv_writer.write_row(orphan_record)

        @logger.info "Found orphaned pool on Gitaly: #{orphan_record.inspect}" if @verbose
      end
    end
  end
end
