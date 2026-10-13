# frozen_string_literal: true

module Gitlab
  module Database
    module PgAsh
      # Runs the rollup and retention functions that upstream pg_ash schedules
      # with pg_cron. Each function takes its own advisory lock and keeps a
      # watermark, so an overlapping or repeated call is a no-op.
      class Maintenance
        UnknownTaskError = Class.new(ArgumentError)

        TASKS = %w[rollup_minute rollup_hour rotate rollup_cleanup].freeze

        def initialize(connection = ApplicationRecord.connection)
          @connection = connection
        end

        # @param task [String] one of TASKS, the ash function to call
        # @return [String] what the function reported
        def run(task)
          task = task.to_s
          raise UnknownTaskError, "unknown pg_ash task #{task.inspect}" unless TASKS.include?(task)

          Gitlab::Database::LoadBalancing::SessionMap.current(connection.load_balancer).use_primary do
            PgAsh.execute(connection, "SELECT #{PgAsh::SCHEMA_NAME}.#{task}() AS result")
              .first.fetch('result').to_s
          end
        end

        private

        attr_reader :connection
      end
    end
  end
end
