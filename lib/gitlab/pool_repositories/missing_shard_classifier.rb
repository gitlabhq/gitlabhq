# frozen_string_literal: true

module Gitlab
  module PoolRepositories
    # rubocop:disable CodeReuse/ActiveRecord -- one-off maintenance task
    class MissingShardClassifier
      ValidationError = Class.new(StandardError)

      BATCH_SIZE = 100

      CASE_SELF_CONTAINED = 'self_contained'
      CASE_SILENTLY_LINKED = 'silently_linked'
      CASE_BROKEN = 'broken'
      CASE_UNKNOWN = 'unknown'

      CSV_COLUMNS = [
        { key: :pool_id, header: 'Pool ID' },
        { key: :pool_shard_name, header: 'Pool Shard Name (dead)' },
        { key: :pool_disk_path, header: 'Pool Disk Path' },
        { key: :project_id, header: 'Project ID' },
        { key: :project_path, header: 'Project Path' },
        { key: :project_shard, header: 'Project Shard (current)' },
        { key: :classification, header: 'Classification' },
        { key: :gitaly_pool_path, header: 'Gitaly Pool Path' },
        { key: :notes, header: 'Notes' }
      ].freeze

      attr_reader :results

      def initialize(shard_names:, logger:, output_file:)
        @shard_names = Array(shard_names).map(&:to_s).map(&:strip).reject(&:blank?)
        @logger = logger
        @output_file = output_file
        @results = { CASE_SELF_CONTAINED => 0, CASE_SILENTLY_LINKED => 0, CASE_BROKEN => 0, CASE_UNKNOWN => 0 }
      end

      def run!
        validate!
        csv_writer
        log "Starting classification of pool repository members on dead shards: #{@shard_names.join(', ')}"

        classify_pools

        report
      ensure
        @csv_writer&.close
      end

      private

      def validate!
        raise ValidationError, 'shard_names cannot be empty' if @shard_names.empty?

        return unless @output_file && File.exist?(@output_file)

        raise ValidationError,
          "Refusing to run: #{@output_file} already exists. " \
            'Use a new output file per run to preserve previous audit records.'
      end

      def csv_writer
        @csv_writer ||= CsvWriter.new(@output_file, columns: CSV_COLUMNS)
      end

      def classify_pools
        shards = Shard.where(name: @shard_names)
        unresolved = @shard_names - shards.map(&:name)
        @logger.warn "No shard record found for: #{unresolved.join(', ')}" if unresolved.any?

        dead_shard_ids = shards.pluck(:id)

        if dead_shard_ids.empty?
          log "No matching shards found in database. Nothing to classify."
          return
        end

        pools = PoolRepository
          .for_shard(dead_shard_ids)
          .where(source_project_id: nil)
          .where_exists(Project.where(Project.arel_table[:pool_repository_id].eq(PoolRepository.arel_table[:id])))
          .includes(:shard)

        pool_count = pools.count
        log "Found #{pool_count} sourceless pools on dead shards with member projects"

        pools.find_each(batch_size: BATCH_SIZE) do |pool|
          classify_pool_members(pool)
        end
      end

      def classify_pool_members(pool)
        pool.member_projects.includes(:route).find_each(batch_size: BATCH_SIZE) do |project|
          classification, pool_path, notes = classify_project(project)
          write_and_count(build_record(pool, project, classification, pool_path, notes))
        rescue StandardError => e
          write_and_count(build_record(pool, project, CASE_UNKNOWN, nil, "Error: #{e.message}"))
          @logger.error "Error classifying project #{project.id} in pool #{pool.id}: #{e.message}"
        end
      end

      def classify_project(project)
        return [CASE_BROKEN, nil, 'Repository does not exist on disk'] unless project.repository.raw.exists?

        gitaly_pool = project.repository.object_pool
        return [CASE_SELF_CONTAINED, nil, 'No object pool linked on current shard'] unless gitaly_pool

        [CASE_SILENTLY_LINKED, gitaly_pool.relative_path,
          "Linked to on-disk pool: #{gitaly_pool.relative_path} on #{project.repository_storage}"]
      end

      def build_record(pool, project, classification, gitaly_pool_path, notes)
        {
          pool_id: pool.id,
          pool_shard_name: pool.shard_name,
          pool_disk_path: pool.disk_path,
          project_id: project.id,
          project_path: project.full_path,
          project_shard: project.repository_storage,
          classification: classification,
          gitaly_pool_path: gitaly_pool_path,
          notes: notes
        }
      end

      def write_and_count(record)
        csv_writer.write_row(record)
        csv_writer.flush
        @results[record[:classification]] += 1

        log "  Project #{record[:project_id]} (#{record[:project_path]}): #{record[:classification]}"
      end

      def report
        log ""
        log Rainbow("=== Classification Report ===").cyan
        log "Self-contained: #{@results[CASE_SELF_CONTAINED]}"
        log "Silently linked: #{@results[CASE_SILENTLY_LINKED]}"
        log "Broken: #{@results[CASE_BROKEN]}"
        log "Unknown/Error: #{@results[CASE_UNKNOWN]}"
        log "Total: #{@results.values.sum}"
      end

      def log(message)
        @logger.info(message)
      end
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
