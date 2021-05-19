# frozen_string_literal: true

module Pages
  class MigrateFromLegacyStorageService
    def initialize(logger, ignore_invalid_entries:, mark_projects_as_not_deployed:)
      @logger = logger
      @ignore_invalid_entries = ignore_invalid_entries
      @mark_projects_as_not_deployed = mark_projects_as_not_deployed

      @migrated = 0
      @errored = 0
      @counters_lock = Mutex.new
    end

    def execute_with_threads(threads:, batch_size:)
      @queue = SizedQueue.new(1)

      migration_threads = start_migration_threads(threads)

      ProjectPagesMetadatum.only_on_legacy_storage.each_batch(of: batch_size) do |batch|
        @queue.push(batch)
      end

      @queue.close

      @logger.info(message: "Pages legacy storage migration: Waiting for threads to finish...")
      migration_threads.each(&:join)

      { migrated: @migrated, errored: @errored }
    end

    def execute_for_batch(project_ids)
      batch = ProjectPagesMetadatum.only_on_legacy_storage.where(project_id: project_ids) # rubocop: disable CodeReuse/ActiveRecord

      process_batch(batch)

      { migrated: @migrated, errored: @errored }
    end

    private

    def start_migration_threads(count)
      Array.new(count) do
        Thread.new do
          while batch = @queue.pop
            Rails.application.executor.wrap do
              process_batch(batch)
            end
          end
        end
      end
    end

    def process_batch(batch)
      batch.with_project_route_and_deployment.each do |metadatum|
        project = metadatum.project

        migrate_project(project)
      end

      @logger.info(message: "Pages legacy storage migration: batch processed", migrated: @migrated, errored: @errored)
    rescue StandardError => e
      # This method should never raise exception otherwise all threads might be killed
      # and this will result in queue starving (and deadlock)
      Gitlab::ErrorTracking.track_exception(e)
      @logger.error(message: "Pages legacy storage migration: failed processing a batch: #{e.message}")
    end

    def migrate_project(project)
      result = nil
      time = Benchmark.realtime do
        result = ::Pages::MigrateLegacyStorageToDeploymentService.new(project,
                                                                      ignore_invalid_entries: @ignore_invalid_entries,
                                                                      mark_projects_as_not_deployed: @mark_projects_as_not_deployed).execute
      end

      if result[:status] == :success
        @logger.info(message: "Pages legacy storage migration: project migrated: #{result[:message]}", project_id: project.id, pages_path: project.pages_path, duration: time.round(2))
        @counters_lock.synchronize { @migrated += 1 }
      else
        @logger.error(message: "Pages legacy storage migration: project failed to be migrated: #{result[:message]}", project_id: project.id, pages_path: project.pages_path, duration: time.round(2))
        @counters_lock.synchronize { @errored += 1 }
      end
    rescue StandardError => e
      @counters_lock.synchronize { @errored += 1 }
      @logger.error(message: "Pages legacy storage migration: project failed to be migrated: #{result[:message]}", project_id: project&.id, pages_path: project&.pages_path)
      Gitlab::ErrorTracking.track_exception(e, project_id: project&.id)
    end
  end
end
