# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module Observers
        # This observer gathers statistics from the pg_stat_statements extension.
        # Notice that this extension is not installed by default. In case it cannot
        # be found, the observer does nothing and doesn't throw an error.
        class QueryStatistics < MigrationObserver
          include Gitlab::Database::SchemaHelpers

          def before
            return unless enabled?

            connection.execute('select pg_stat_statements_reset()')
          end

          def record(observation)
            return unless enabled?

            observation.query_statistics = connection.execute(<<~SQL)
              SELECT query, calls, total_time, max_time, mean_time, rows
              FROM pg_stat_statements
              ORDER BY total_time DESC
            SQL
          end

          private

          def enabled?
            function_exists?(:pg_stat_statements_reset) && connection.view_exists?(:pg_stat_statements)
          end
        end
      end
    end
  end
end
