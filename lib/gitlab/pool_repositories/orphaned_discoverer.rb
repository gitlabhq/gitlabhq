# frozen_string_literal: true

module Gitlab
  module PoolRepositories
    class OrphanedDiscoverer
      POOLS_BATCH_SIZE = 100
      STATEMENT_TIMEOUT = '5min'

      def initialize(
        output_file:, logger: nil, verbose: false, csv_writer: nil, discovery_service: nil,
        storage_scanner: nil)
        raise ArgumentError, 'output_file is required' if output_file.blank?

        @logger = logger || Logger.new($stdout)
        @output_file = output_file
        @verbose = verbose
        @orphaned_pools = []
        @csv_writer = csv_writer || CsvWriter.new(output_file)
        @discovery_service = discovery_service || DiscoveryService.new(@logger, @verbose)
        @storage_scanner = storage_scanner
      end

      attr_reader :orphaned_pools

      def run!
        log "Starting orphaned pool repository discovery..."
        log "Verbose mode: #{@verbose}"

        with_extended_statement_timeout do
          discover_orphaned_pools
        end
        report_results
      ensure
        @csv_writer.close
      end

      private

      def log(message)
        @logger.info(message)
      end

      def discover_orphaned_pools
        scan_all_pools
        scan_gitaly_pools
      end

      def scan_all_pools
        log "Scanning all pool repositories..."

        # rubocop:disable CodeReuse/ActiveRecord -- Scanning all pools for orphans
        PoolRepository.includes(:member_projects).find_each(batch_size: POOLS_BATCH_SIZE) do |pool|
          check_pool(pool)
        rescue StandardError => e
          @logger.error "Error checking pool #{pool.id}: #{e.message}"
          @logger.debug e.backtrace.join("\n") if @verbose
        end
        # rubocop:enable CodeReuse/ActiveRecord
      end

      def scan_gitaly_pools
        log "Scanning Gitaly storage for pools not in Rails DB..."

        @storage_scanner ||= StorageScanner.new(@logger, @verbose, @discovery_service, @csv_writer)

        @storage_scanner.scan_all_storages

        @orphaned_pools.concat(@storage_scanner.orphaned_pools)
      end

      def check_pool(pool)
        reasons = []
        reasons << :pool_no_source_project if pool.source_project_id.nil?
        reasons << :pool_in_obsolete_state if pool.state == 'obsolete'
        reasons << :pool_in_db_no_projects if pool.member_projects.empty?

        gitaly_relative_path = check_disk_path_mismatch(pool)
        reasons << :disk_path_mismatch if gitaly_relative_path

        log_orphan(pool, reasons, gitaly_relative_path: gitaly_relative_path) if reasons.any?
      end

      def check_disk_path_mismatch(pool)
        pool.member_projects.each do |member_project|
          gitaly_pool = fetch_gitaly_pool(member_project)
          next unless gitaly_pool

          return gitaly_pool.relative_path unless paths_match?(pool.disk_path, gitaly_pool.relative_path)

          return nil
        end

        nil
      end

      def fetch_gitaly_pool(project)
        return unless project.repository.exists?

        project.repository.object_pool
      rescue StandardError => e
        @logger.debug "Failed to fetch Gitaly pool for project #{project.id}: #{e.message}" if @verbose
        nil
      end

      def paths_match?(disk_path, relative_path)
        disk_path == relative_path.chomp('.git')
      end

      def log_orphan(pool_repository, reasons, gitaly_relative_path: nil)
        orphan_record = OrphanRecord.from_pool(pool_repository, reasons, gitaly_relative_path)

        @orphaned_pools << orphan_record
        @csv_writer.write_row(orphan_record)

        log_message = "Found orphaned pool: #{orphan_record.inspect}"
        @logger.info log_message if @verbose
      end

      def report_results
        log ""
        log Rainbow("=== Orphaned Pool Repository Discovery Report ===").cyan
        log "Total orphaned pools found: #{@orphaned_pools.size}"

        if @orphaned_pools.empty?
          log Rainbow("No orphaned pools detected!").green
          return
        end

        @orphaned_pools.group_by { |p| p[:reason_codes] }.each do |reason_codes, pools|
          log ""
          log Rainbow("#{reason_codes} (#{pools.size})").yellow
          pools.each do |pool|
            log "  - Pool ID: #{pool[:pool_id]}, Disk Path: #{pool[:disk_path]}, State: #{pool[:state]}"
          end
        end

        log ""
        log Rainbow("Detailed results saved to: #{@output_file}").green
      end

      def with_extended_statement_timeout
        ApplicationRecord.connection.execute("SET statement_timeout = '#{STATEMENT_TIMEOUT}'")
        yield
      ensure
        ApplicationRecord.connection.execute('RESET statement_timeout')
      end
    end
  end
end
