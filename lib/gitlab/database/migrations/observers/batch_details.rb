# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module Observers
        class BatchDetails < MigrationObserver
          FILE_NAME = 'batch-details.json'

          def before
            @started_at = get_time
          end

          def after
            @finished_at = get_time
          end

          def record
            File.open(path, 'wb') { |file| file.write(file_contents.to_json) }
          end

          private

          attr_reader :started_at, :finished_at

          def file_contents
            { time_spent: time_spent }.merge(job_meta)
          end

          def get_time
            Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end

          def time_spent
            @time_spent ||= (finished_at - started_at).round(2)
          end

          def path
            File.join(output_dir, FILE_NAME)
          end

          def job_meta
            meta = observation.meta

            return {} unless meta

            meta[:job_meta].to_h
          end
        end
      end
    end
  end
end
