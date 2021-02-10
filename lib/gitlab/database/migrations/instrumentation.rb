# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      Observation = Struct.new(
        :migration,
        :walltime,
        :success
      )

      class Instrumentation
        attr_reader :observations

        def initialize
          @observations = []
        end

        def observe(migration, &block)
          observation = Observation.new(migration)
          observation.success = true

          exception = nil

          observation.walltime = Benchmark.realtime do
            yield
          rescue => e
            exception = e
            observation.success = false
          end

          record_observation(observation)

          raise exception if exception

          observation
        end

        private

        def record_observation(observation)
          @observations << observation
        end
      end
    end
  end
end
