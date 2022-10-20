# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class TestBackgroundRunner < BaseBackgroundRunner
        def initialize(result_dir:)
          super(result_dir: result_dir, connection: ActiveRecord::Migration.connection)
          @job_coordinator = Gitlab::BackgroundMigration.coordinator_for_database(Gitlab::Database::MAIN_DATABASE_NAME)
        end

        def traditional_background_migrations
          @job_coordinator.pending_jobs
        end

        def jobs_by_migration_name
          traditional_background_migrations.group_by { |j| class_name_for_job(j) }
                                           .transform_values(&:shuffle)
        end

        private

        def run_job(job)
          Gitlab::BackgroundMigration.perform(job.args[0], job.args[1])
        end

        def class_name_for_job(job)
          job.args[0]
        end
      end
    end
  end
end
