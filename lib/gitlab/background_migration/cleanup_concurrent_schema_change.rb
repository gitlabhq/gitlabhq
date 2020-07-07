# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Base class for background migration for rename/type changes.
    class CleanupConcurrentSchemaChange
      include Database::MigrationHelpers

      # table - The name of the table the migration is performed for.
      # old_column - The name of the old (to drop) column.
      # new_column - The name of the new column.
      def perform(table, old_column, new_column)
        return unless column_exists?(table, new_column) && column_exists?(table, old_column)

        rows_to_migrate = define_model_for(table)
          .where(new_column => nil)
          .where
          .not(old_column => nil)

        if rows_to_migrate.any?
          BackgroundMigrationWorker.perform_in(
            RESCHEDULE_DELAY,
            self.class.name,
            [table, old_column, new_column]
          )
        else
          cleanup_concurrent_schema_change(table, old_column, new_column)
        end
      end

      def cleanup_concurrent_schema_change(_table, _old_column, _new_column)
        raise NotImplementedError
      end

      # These methods are necessary so we can re-use the migration helpers in
      # this class.
      def connection
        ActiveRecord::Base.connection
      end

      def method_missing(name, *args, &block)
        connection.__send__(name, *args, &block) # rubocop: disable GitlabSecurity/PublicSend
      end

      def respond_to_missing?(*args)
        connection.respond_to?(*args) || super
      end

      def define_model_for(table)
        Class.new(ActiveRecord::Base) do
          self.table_name = table
        end
      end
    end
  end
end
