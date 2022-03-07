# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class TestBackgroundRunner
        # TODO - build a rake task to call this method, and support it in the gitlab-com-database-testing project.
        # Until then, we will inject a migration with a very high timestamp during database testing
        # that calls this class to run jobs
        # See https://gitlab.com/gitlab-org/database-team/gitlab-com-database-testing/-/issues/41 for details

        def initialize
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
          jobs_to_run.each do |_migration_name, jobs|
            run_until = duration_per_migration_type.from_now
            jobs.shuffle.each do |j|
              break if run_until <= Time.current

              run_job(j)
            end
          end
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
