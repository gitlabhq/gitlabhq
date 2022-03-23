# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class TestBackgroundRunner
        attr_reader :result_dir

        def initialize(result_dir:)
          @result_dir = result_dir
          @job_coordinator = Gitlab::BackgroundMigration.coordinator_for_database(Gitlab::Database::MAIN_DATABASE_NAME)
        end

        def traditional_background_migrations
          @job_coordinator.pending_jobs
        end

        def run_jobs(for_duration:)
          jobs_to_run = traditional_background_migrations.group_by { |j| class_name_for_job(j) }
          return if jobs_to_run.empty?

          # without .to_f, we do integer division
          # For example, 3.minutes / 2 == 1.minute whereas 3.minutes / 2.to_f == (1.minute + 30.seconds)
          duration_per_migration_type = for_duration / jobs_to_run.count.to_f
          jobs_to_run.each do |migration_name, jobs|
            run_until = duration_per_migration_type.from_now

            run_jobs_for_migration(migration_name: migration_name, jobs: jobs, run_until: run_until)
          end
        end

        private

        def run_jobs_for_migration(migration_name:, jobs:, run_until:)
          per_background_migration_result_dir = File.join(@result_dir, migration_name)

          instrumentation = Instrumentation.new(result_dir: per_background_migration_result_dir)
          batch_names = (1..).each.lazy.map { |i| "batch_#{i}"}

          jobs.shuffle.each do |j|
            break if run_until <= Time.current

            instrumentation.observe(version: nil, name: batch_names.next, connection: ActiveRecord::Migration.connection) do
              run_job(j)
            end
          end
        end

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
