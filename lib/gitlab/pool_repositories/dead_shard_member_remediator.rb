# frozen_string_literal: true

require 'csv'

module Gitlab
  module PoolRepositories
    class DeadShardMemberRemediator
      ValidationError = Class.new(StandardError)

      VALID_CLASSIFICATIONS = %w[silently_linked].freeze

      CSV_COLUMNS = [
        { key: :project_id, header: 'Project ID' },
        { key: :project_path, header: 'Project Path' },
        { key: :classification, header: 'Classification' },
        { key: :old_pool_id, header: 'Old Pool ID' },
        { key: :new_pool_id, header: 'New Pool ID' },
        { key: :action, header: 'Action' },
        { key: :status, header: 'Status' },
        { key: :notes, header: 'Notes' }
      ].freeze

      attr_reader :results

      def initialize(input_file:, output_file:, logger:, dry_run: true, classifications: nil)
        @input_file = input_file
        @output_file = output_file
        @logger = logger
        @dry_run = dry_run
        @classifications = Array(classifications || VALID_CLASSIFICATIONS).map(&:strip).reject(&:blank?)
        @results = { 'relinked' => 0, 'skipped' => 0, 'error' => 0 }
      end

      def run!
        validate!
        @csv_writer = CsvWriter.new(@output_file, columns: CSV_COLUMNS)

        log "Starting remediation (dry_run=#{@dry_run}) for classifications: #{@classifications.join(', ')}"
        log "Reading classification CSV from #{@input_file}"

        process_csv

        report
      ensure
        @csv_writer&.close
      end

      private

      def validate!
        raise ValidationError, "Input file does not exist: #{@input_file}" unless File.exist?(@input_file)
        raise ValidationError, 'No valid classifications specified' if @classifications.empty?

        unknown = @classifications - VALID_CLASSIFICATIONS
        raise ValidationError, "Unknown classifications: #{unknown.join(', ')}" if unknown.any?

        return unless @output_file && File.exist?(@output_file)

        raise ValidationError,
          "Refusing to run: #{@output_file} already exists. " \
            'Use a new output file per run to preserve previous audit records.'
      end

      def process_csv
        CSV.foreach(@input_file, headers: true) do |row|
          process_row(row)
        rescue ActiveRecord::RecordNotFound => e
          write_result(row, nil, 'skipped', 'skipped', "Not found: #{e.message}")
          @results['skipped'] += 1
        rescue StandardError => e
          write_result(row, nil, 'error', 'error', "Error: #{e.message}")
          @results['error'] += 1
          @logger.error "Error remediating project #{row['Project ID']}: #{e.message}"
        end
      end

      def process_row(row)
        classification = row['Classification']
        unless @classifications.include?(classification)
          write_result(row, nil, 'skipped', 'skipped', "Classification '#{classification}' not in target list")
          @results['skipped'] += 1
          return
        end

        project = Project.find(row['Project ID'])
        dead_pool = PoolRepository.find(row['Pool ID'])
        reason = stale_reason(row, project, dead_pool)
        return skip_stale(row, reason) if reason
        return skip_live_shard(row, dead_pool) if live_shard?(dead_pool)

        remediate_silently_linked(row, project, dead_pool)
      end

      def remediate_silently_linked(row, project, dead_pool)
        gitaly_disk_path = row['Gitaly Pool Path'].delete_suffix('.git')
        new_pool = find_or_initialize_pool(project.repository_storage, gitaly_disk_path, dead_pool)

        if new_pool.persisted? && !new_pool.ready?
          write_result(row, new_pool.id, 'skipped', 'skipped',
            "Existing pool #{new_pool.id} on #{project.repository_storage} is #{new_pool.state}")
          @results['skipped'] += 1
          return
        end

        if @dry_run
          write_result(row, new_pool.id, 'relink (dry run)', 'dry_run',
            "Would relink to pool #{new_pool.id || '(new)'} on #{project.repository_storage}")
          @results['relinked'] += 1
          return
        end

        relinked = false

        dead_pool.transaction do
          project.lock!

          unless project.pool_repository_id == dead_pool.id
            write_result(row, nil, 'skipped', 'skipped',
              "Stale: pool_repository_id changed to #{project.pool_repository_id || 'nil'} before update")
            @results['skipped'] += 1
            raise ActiveRecord::Rollback
          end

          new_pool.save! if new_pool.new_record?
          project.update!(pool_repository: new_pool)
          relinked = true
        end

        return unless relinked

        write_result(row, new_pool.id, 'relinked', 'success',
          "Relinked to pool #{new_pool.id} on #{project.repository_storage}")
        @results['relinked'] += 1
      end

      def stale_reason(row, project, dead_pool)
        if project.pool_repository_id != dead_pool.id
          return "pool_repository_id is #{project.pool_repository_id || 'nil'}, expected #{dead_pool.id}"
        end

        if project.repository_storage != row['Project Shard (current)']
          return "project moved to #{project.repository_storage} since classification"
        end

        expected_path = "#{dead_pool.disk_path}.git"
        return if row['Classification'] != 'silently_linked' || row['Gitaly Pool Path'] == expected_path

        "on-disk pool #{row['Gitaly Pool Path']} does not match #{expected_path}"
      end

      def skip_stale(row, reason)
        write_result(row, nil, 'skipped', 'skipped', "Stale: #{reason}")
        @results['skipped'] += 1
      end

      def live_shard?(pool)
        configured_storages.include?(pool.shard_name)
      end

      def configured_storages
        @configured_storages ||= Gitlab.config.repositories.storages.keys.map(&:to_s)
      end

      def skip_live_shard(row, dead_pool)
        write_result(row, nil, 'skipped', 'skipped',
          "Pool shard #{dead_pool.shard_name} is still configured")
        @results['skipped'] += 1
      end

      def find_or_initialize_pool(shard_name, disk_path, source_pool)
        existing = PoolRepository.by_disk_path_and_shard_name(disk_path, shard_name).first
        return existing if existing

        PoolRepository.new(
          disk_path: disk_path,
          shard: Shard.find_by_name(shard_name),
          state: 'ready',
          source_project_id: nil,
          organization: source_pool.organization
        )
      end

      def write_result(row, new_pool_id, action, status, notes)
        record = {
          project_id: row['Project ID'],
          project_path: row['Project Path'],
          classification: row['Classification'],
          old_pool_id: row['Pool ID'],
          new_pool_id: new_pool_id,
          action: action,
          status: status,
          notes: notes
        }
        @csv_writer.write_row(record)
        @csv_writer.flush
        log "  Project #{record[:project_id]} (#{record[:project_path]}): #{action} — #{notes}"
      end

      def report
        log ""
        log Rainbow("=== Remediation Report ===").cyan
        log "Mode: #{@dry_run ? 'DRY RUN' : 'LIVE'}"
        log "Relinked (silently_linked): #{@results['relinked']}"
        log "Skipped: #{@results['skipped']}"
        log "Errors: #{@results['error']}"
        log "Total: #{@results.values.sum}"
      end

      def log(message)
        @logger.info(message)
      end
    end
  end
end
