# frozen_string_literal: true

module Pages
  class MigrateFromLegacyStorageService
    def initialize(logger, migration_threads, batch_size)
      @logger = logger
      @migration_threads = migration_threads
      @batch_size = batch_size

      @migrated = 0
      @errored = 0
      @counters_lock = Mutex.new
    end

    def execute
      @queue = SizedQueue.new(1)

      threads = start_migration_threads

      ProjectPagesMetadatum.only_on_legacy_storage.each_batch(of: @batch_size) do |batch|
        @queue.push(batch)
      end

      @queue.close

      @logger.info("Waiting for threads to finish...")
      threads.each(&:join)

      { migrated: @migrated, errored: @errored }
    end

    def start_migration_threads
      Array.new(@migration_threads) do
        Thread.new do
          Rails.application.executor.wrap do
            while batch = @queue.pop
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

      @logger.info("#{@migrated} projects are migrated successfully, #{@errored} projects failed to be migrated")
    end

    def migrate_project(project)
      result = nil
      time = Benchmark.realtime do
        result = ::Pages::MigrateLegacyStorageToDeploymentService.new(project).execute
      end

      if result[:status] == :success
        @logger.info("project_id: #{project.id} #{project.pages_path} has been migrated in #{time} seconds")
        @counters_lock.synchronize { @migrated += 1 }
      else
        @logger.error("project_id: #{project.id} #{project.pages_path} failed to be migrated in #{time} seconds: #{result[:message]}")
        @counters_lock.synchronize { @errored += 1 }
      end
    rescue => e
      @counters_lock.synchronize { @errored += 1 }
      @logger.error("#{e.message} project_id: #{project&.id}")
      Gitlab::ErrorTracking.track_exception(e, project_id: project&.id)
    end
  end
end
