# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration for cleaning up a concurrent column type changeb.
    class CleanupConcurrentTypeChange < CleanupConcurrentSchemaChange
      RESCHEDULE_DELAY = 10.minutes

      def cleanup_concurrent_schema_change(table, old_column, new_column)
        cleanup_concurrent_column_type_change(table, old_column)
      end
    end
  end
end
