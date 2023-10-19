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

          def record
            return unless enabled?

            observation.query_statistics = connection.execute(<<~SQL)
              SELECT
                query,
                calls,
                total_exec_time + total_plan_time AS total_time,
                max_exec_time + max_plan_time AS max_time,
                mean_exec_time + mean_plan_time AS mean_time,
                "rows"
              FROM pg_stat_statements
              WHERE pg_get_userbyid(userid) = current_user
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
