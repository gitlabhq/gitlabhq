# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module WraparoundAutovacuum
        # This is used for partitioning CI tables because the autovacuum for wraparound
        # prevention can take many hours to complete on some of the tables and this in
        # turn blocks the post deployment migrations pipeline.
        # Intended workflow for this helper:
        # 1. Introduce a migration that is guarded with this helper for self-managed
        #    so that the tests and everything else depending on it can reflect the changes
        # 2. Introduce the migration again for .com
        #    so that we can keep trying until it succeeds on .com
        def can_execute_on?(*tables)
          return true unless Gitlab.com_except_jh?
          return true unless wraparound_prevention_on_tables?(tables)

          Gitlab::AppLogger.info(message: "Wraparound prevention vacuum detected", class: self.class)
          say "Wraparound prevention vacuum detected, skipping migration"
          false
        end

        def wraparound_prevention_on_tables?(tables)
          Gitlab::Database::PostgresAutovacuumActivity.reset_column_information

          Gitlab::Database::PostgresAutovacuumActivity
            .wraparound_prevention
            .for_tables(tables)
            .any?
        end
      end
    end
  end
end
