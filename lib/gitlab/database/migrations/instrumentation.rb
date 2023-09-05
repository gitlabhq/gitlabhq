# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class Instrumentation
        STATS_FILENAME = 'migration-stats.json'

        def initialize(result_dir:, observer_classes: ::Gitlab::Database::Migrations::Observers.all_observers)
          @observer_classes = observer_classes
          @result_dir = result_dir
        end

        def observe(version:, name:, connection:, meta: {}, &block)
          observation = Observation.new(version: version, name: name, success: false, meta: meta)

          per_migration_result_dir = File.join(@result_dir, name)

          FileUtils.mkdir_p(per_migration_result_dir)

          observers = observer_classes.map { |c| c.new(observation, per_migration_result_dir, connection) }

          on_each_observer(observers) { |observer| observer.before }

          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          yield

          observation.success = true

          observation
        rescue StandardError => error
          observation.error_message = error.message

          raise
        ensure
          observation.walltime = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

          on_each_observer(observers) { |observer| observer.after }
          on_each_observer(observers) { |observer| observer.record }

          record_observation(observation, destination_dir: per_migration_result_dir)
        end

        private

        attr_reader :observer_classes

        def record_observation(observation, destination_dir:)
          stats_file_location = File.join(destination_dir, STATS_FILENAME)
          File.write(stats_file_location, observation.to_json)
        end

        def on_each_observer(observers, &block)
          observers.each do |observer|
            yield observer
          rescue StandardError => e
            Gitlab::AppLogger.error("Migration observer #{observer.class} failed with: #{e}")
          end
        end
      end
    end
  end
end
