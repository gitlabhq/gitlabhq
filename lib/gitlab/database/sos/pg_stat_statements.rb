# frozen_string_literal: true

module Gitlab
  module Database
    module Sos
      class PgStatStatements < BaseDbStatsHandler
        include Gitlab::Utils::StrongMemoize

        QUERY = <<~SQL
          SELECT now() AS timestamp, *
          FROM pg_stat_statements;
        SQL

        def run
          return unless pg_stat_statements_installed?

          result = execute_query(QUERY)
          write_to_csv("pg_stat_statements", result, include_timestamp: true)
        end

        def pg_stat_statements_installed?
          query = "select exists(select 1 from pg_extension where extname = 'pg_stat_statements');"
          result = execute_query(query)
          result.first['exists']
        end
        strong_memoize_attr :pg_stat_statements_installed?
      end
    end
  end
end
