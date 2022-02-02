# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      class Instrumentation
        STATS_FILENAME = 'migration-stats.json'

        attr_reader :observations

        def initialize(result_dir:, observer_classes: ::Gitlab::Database::Migrations::Observers.all_observers)
          @observer_classes = observer_classes
          @observations = []
          @result_dir = result_dir
        end

        def observe(version:, name:, connection:, &block)
          observation = Observation.new(version: version, name: name, success: false)

          observers = observer_classes.map { |c| c.new(observation, @result_dir, connection) }

          on_each_observer(observers) { |observer| observer.before }

          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          yield

          observation.success = true

          observation
        ensure
          observation.walltime = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

          on_each_observer(observers) { |observer| observer.after }
          on_each_observer(observers) { |observer| observer.record }

          record_observation(observation)
        end

        private

        attr_reader :observer_classes

        def record_observation(observation)
          @observations << observation
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
