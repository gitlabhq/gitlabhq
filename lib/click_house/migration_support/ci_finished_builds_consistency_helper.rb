# frozen_string_literal: true

module ClickHouse # rubocop:disable Gitlab/BoundedContexts -- Existing module
  module MigrationSupport
    class CiFinishedBuildsConsistencyHelper
      MIGRATION_NAME = 'BackfillCiFinishedBuildsToClickHouse'
      CACHE_KEY = 'ci_finished_builds_backfill_in_progress'
      CACHE_TTL = 1.hour

      class << self
        def backfill_in_progress?
          Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
            migration_in_progress?
          end
        end

        private

        def migration_in_progress?
          migration = find_migration
          return false unless migration

          !migration.finished? && !migration.finalized?
        end

        def find_migration
          Gitlab::Database::SharedModel.using_connection(::Ci::ApplicationRecord.connection) do
            Gitlab::Database::BackgroundMigration::BatchedMigration
              .for_gitlab_schema(:gitlab_ci)
              .for_job_class(MIGRATION_NAME)
              .first
          end
        end
      end
    end
  end
end
