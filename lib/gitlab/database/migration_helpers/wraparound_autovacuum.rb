# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module WraparoundAutovacuum
        # This is used for partitioning CI tables because the autovacuum for wraparound
        # prevention can take many hours to complete on some of the tables and this in
        # turn blocks the post deployment migrations pipeline.
        # Intended workflow for this helper:
        # 1. Introduce a migration that is guarded with this helper
        # 2. Check that the migration was successfully executed on .com
        # 3. Introduce the migration again for self-managed.
        #
        def can_execute_on?(*tables)
          return false unless Gitlab.com_except_jh? || Gitlab.dev_or_test_env?

          if wraparound_prevention_on_tables?(tables)
            Gitlab::AppLogger.info(message: "Wraparound prevention vacuum detected", class: self.class)
            say "Wraparound prevention vacuum detected, skipping migration"
            return false
          end

          true
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
