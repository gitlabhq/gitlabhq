# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module RedisHelpers
        SCAN_START_CURSOR = '0'

        # Check if the migration exists before enqueueing the worker
        def queue_redis_migration_job(job_name)
          RedisMigrationWorker.fetch_migrator!(job_name)
          RedisMigrationWorker.perform_async(job_name, SCAN_START_CURSOR)
        end
      end
    end
  end
end
