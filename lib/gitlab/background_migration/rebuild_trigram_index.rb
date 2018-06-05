# frozen_string_literal: true
module Gitlab
  module BackgroundMigration
    # Rebuilds an existing trigram index
    class RebuildTrigramIndex < ActiveRecord::Migration
      include Gitlab::Database::MigrationHelpers

      def perform(table, column)
        return unless Gitlab::Database.postgresql?

        disable_statement_timeout

        index_name = "index_#{table}_on_#{column}_trigram"
        index_name_old = "#{index_name}_old"

        if index_exists_by_name?(table, index_name)
          if index_exists_by_name?(table, index_name_old)
            raise "Failed to rename existing index since this index already exists: #{index_name_old}" \
              "Consider removing the index and re-run the migration."
          end

          rename_index table, index_name, index_name_old
        end

        execute "CREATE INDEX CONCURRENTLY #{index_name} ON #{table} USING gin(#{column} gin_trgm_ops);"

        if index_exists_by_name?(table, index_name_old)
          remove_concurrent_index_by_name table, index_name_old
        end
      end
    end
  end
end
