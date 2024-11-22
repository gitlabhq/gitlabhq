# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class BaseBackgroundRunner
        attr_reader :result_dir, :connection

        def initialize(result_dir:, connection:)
          @result_dir = result_dir
          @connection = connection
        end

        def jobs_by_migration_name
          raise NotImplementedError, 'subclass must implement'
        end

        def run_job(job)
          raise NotImplementedError, 'subclass must implement'
        end

        def print_job_progress(batch_name, job)
          # Subclasses can implement to print job progress
        end

        def run_jobs(for_duration:)
          jobs_to_run = jobs_by_migration_name
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
          puts("Sampling jobs for #{migration_name}") # rubocop:disable Rails/Output -- This runs only in pipelines and should output to the pipeline log
          per_background_migration_result_dir = File.join(@result_dir, migration_name)

          instrumentation = Instrumentation.new(result_dir: per_background_migration_result_dir,
            observer_classes: observers)

          batch_names = (1..).each.lazy.map { |i| "batch_#{i}" }

          jobs.each do |j|
            break if run_until <= Time.current

            batch_name = batch_names.next

            print_job_progress(batch_name, j)

            meta = { job_meta: job_meta(j) }

            instrumentation.observe(version: nil,
              name: batch_name,
              connection: connection,
              meta: meta) do
              run_job(j)
            end
          end
        end

        def job_meta(_job)
          {}
        end

        def observers
          ::Gitlab::Database::Migrations::Observers.all_observers
        end
      end
    end
  end
end
