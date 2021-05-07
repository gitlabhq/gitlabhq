# frozen_string_literal: true

module Gitlab
  module Database
    module RenameTableHelpers
      def rename_table_safely(old_table_name, new_table_name)
        with_lock_retries do
          rename_table(old_table_name, new_table_name)
          execute("CREATE VIEW #{old_table_name} AS SELECT * FROM #{new_table_name}")
        end
      end

      def undo_rename_table_safely(old_table_name, new_table_name)
        with_lock_retries do
          execute("DROP VIEW IF EXISTS #{old_table_name}")
          rename_table(new_table_name, old_table_name)
        end
      end

      def finalize_table_rename(old_table_name, new_table_name)
        with_lock_retries do
          execute("DROP VIEW IF EXISTS #{old_table_name}")
        end
      end

      def undo_finalize_table_rename(old_table_name, new_table_name)
        with_lock_retries do
          execute("CREATE VIEW #{old_table_name} AS SELECT * FROM #{new_table_name}")
        end
      end
    end
  end
end
