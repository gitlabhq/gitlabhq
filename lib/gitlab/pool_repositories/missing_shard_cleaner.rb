# frozen_string_literal: true

module Gitlab
  module PoolRepositories
    # Deletes pool_repositories rows that reference permanently
    # decommissioned Gitaly storages and are fully orphaned (no source
    # project and no member projects). Gitaly-side cleanup is impossible
    # for these rows because the storage no longer exists.
    class MissingShardCleaner
      BATCH_SIZE = 500

      CSV_COLUMNS = [
        { key: :pool_id, header: 'Pool ID' },
        { key: :shard_id, header: 'Shard ID' },
        { key: :shard_name, header: 'Shard Name' },
        { key: :disk_path, header: 'Disk Path' },
        { key: :state, header: 'State' },
        { key: :source_project_id, header: 'Source Project ID' },
        { key: :organization_id, header: 'Organization ID' }
      ].freeze

      ValidationError = Class.new(StandardError)

      attr_reader :deleted_count, :skipped_members_count, :csv_count

      def initialize(
        shard_names:, logger:, output_file: nil, deleted_output_file: nil, dry_run: true,
        csv_writer: nil, deleted_csv_writer: nil)
        raise ArgumentError, 'output_file or csv_writer is required' if output_file.nil? && csv_writer.nil?

        @shard_names = Array(shard_names).map(&:to_s).map(&:strip).reject(&:blank?)
        @output_file = output_file
        @deleted_output_file = deleted_output_file
        @csv_writer = csv_writer
        @deleted_csv_writer = deleted_csv_writer
        @logger = logger
        @dry_run = dry_run
        @deleted_count = 0
        @csv_count = 0
        @skipped_members_count = 0
      end

      def run!
        validate!

        # Created only after validation passes, so a rejected run never
        # truncates an existing audit CSV at the same path.
        csv_writer
        deleted_csv_writer unless dry_run

        if shards_by_id.empty?
          logger.info 'No matching shards found. Nothing to clean up.'
          report
          return
        end

        log_excluded_pools_with_members(shards_by_id.keys)
        process_batches(sourceless_pools(shards_by_id.keys))

        report
      ensure
        @csv_writer&.close
        @deleted_csv_writer&.close
      end

      private

      attr_reader :shard_names, :output_file, :deleted_output_file, :logger, :dry_run

      def csv_writer
        @csv_writer ||= CsvWriter.new(output_file, columns: CSV_COLUMNS)
      end

      def deleted_csv_writer
        @deleted_csv_writer ||= CsvWriter.new(deleted_output_file, columns: [{ key: :pool_id, header: 'Pool ID' }])
      end

      def validate!
        raise ValidationError, 'shard_names cannot be empty' if shard_names.empty?

        if !dry_run && deleted_output_file.blank? && @deleted_csv_writer.nil?
          raise ValidationError, 'DELETED_IDS_FILE is required when DRY_RUN=false'
        end

        output_files = [output_file]
        output_files << deleted_output_file unless dry_run
        paths = output_files.compact.map do |path|
          File.join(File.realpath(File.dirname(path)), File.basename(path))
        rescue SystemCallError => e
          raise ValidationError, "Cannot resolve output directory for #{path}: #{e.message}"
        end

        if paths.uniq.size != paths.size
          raise ValidationError, 'OUTPUT_FILE and DELETED_IDS_FILE must be different paths'
        end

        existing_file = output_files.compact.find { |path| File.exist?(path) }

        if existing_file
          raise ValidationError,
            "Refusing to run: #{existing_file} already exists. " \
              'Use a new output file per run to preserve previous audit records.'
        end

        configured = Gitlab.config.repositories.storages.keys.map(&:to_s)
        live_shards = shard_names & configured
        return if live_shards.empty?

        raise ValidationError,
          "Refusing to run: #{live_shards.join(', ')} present in current Gitaly configuration. " \
            'Only permanently decommissioned storages can be cleaned up.'
      end

      # rubocop:disable CodeReuse/ActiveRecord -- one-off maintenance task
      def shards_by_id
        @shards_by_id ||= begin
          shards = Shard.where(name: shard_names).to_a
          unresolved = shard_names - shards.map(&:name)

          if unresolved.any?
            logger.warn "No shards record found for: #{unresolved.join(', ')}. Nothing to clean up for them."
          end

          shards.to_h { |shard| [shard.id, shard.name] }
        end
      end

      def sourceless_pools(shard_ids)
        PoolRepository.for_shard(shard_ids).where(source_project_id: nil)
      end

      def member_projects
        Project.where(Project.arel_table[:pool_repository_id].eq(PoolRepository.arel_table[:id]))
      end

      def log_excluded_pools_with_members(shard_ids)
        @skipped_members_count = sourceless_pools(shard_ids).where_exists(member_projects).count

        logger.info "Orphaned pools on given shards still referenced by projects (excluded): #{@skipped_members_count}"
      end

      def process_batches(scope)
        scope.each_batch(of: BATCH_SIZE) do |batch|
          # The NOT EXISTS filter is applied inside the block, not on the
          # outer each_batch scope, to keep batch-boundary query plans
          # stable (see iterating_tables_in_batches.md).
          orphaned = batch.where_not_exists(member_projects)

          rows = orphaned.to_a
          rows.each { |pool| csv_writer.write_row(csv_row(pool)) }
          @csv_count += rows.size

          next if dry_run

          # Rows must be on disk before the delete commits, or a crash
          # mid-run loses the only recovery record of the deleted batch.
          csv_writer.flush

          deleted_rows = orphaned.where(id: rows.map(&:id)).delete_all_returning(:id)
          @deleted_count += deleted_rows.size
          deleted_rows.each { |row| deleted_csv_writer.write_row(pool_id: row.fetch('id')) }
          deleted_csv_writer.flush

          sleep 0.01 # rest period between delete batches to reduce primary database pressure

          next if deleted_rows.size == rows.size

          logger.warn "Batch mismatch: #{rows.size} rows written to CSV but #{deleted_rows.size} deleted. " \
            'Some rows no longer matched the delete conditions and were skipped.'
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord

      def csv_row(pool)
        {
          pool_id: pool.id,
          shard_id: pool.shard_id,
          shard_name: shards_by_id[pool.shard_id],
          disk_path: pool.disk_path,
          state: pool.state,
          source_project_id: pool.source_project_id,
          organization_id: pool.organization_id
        }
      end

      def report
        logger.info "Recovery CSV: #{csv_count} pool records written."
        logger.info "Recovery CSV saved to #{output_file}" if output_file

        if dry_run
          logger.info 'Dry run complete. No rows were deleted.'
        else
          logger.info "Deleted #{deleted_count} orphaned pool repository rows."
          logger.info "Deleted IDs CSV: #{deleted_count} IDs written."
          logger.info "Deleted IDs CSV saved to #{deleted_output_file}" if deleted_output_file
        end
      end
    end
  end
end
