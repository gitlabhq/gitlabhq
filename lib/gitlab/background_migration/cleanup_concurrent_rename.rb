# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration for cleaning up a concurrent column rename.
    class CleanupConcurrentRename < CleanupConcurrentSchemaChange
      RESCHEDULE_DELAY = 10.minutes

      def cleanup_concurrent_schema_change(table, old_column, new_column)
        cleanup_concurrent_column_rename(table, old_column, new_column)
      end
    end
  end
end
