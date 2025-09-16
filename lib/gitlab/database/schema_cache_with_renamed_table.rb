# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaCacheWithRenamedTable
      # Override methods in ActiveRecord::ConnectionAdapters::SchemaCache
      # https://github.com/rails/rails/blob/v7.2.2.2/activerecord/lib/active_record/connection_adapters/schema_cache.rb

      def clear!
        super

        clear_renamed_tables_cache!
      end

      def clear_data_source_cache!(pool, table_name)
        super

        clear_renamed_tables_cache!
      end

      def primary_keys(pool, table_name)
        super(pool, underlying_table(pool, table_name))
      end

      def columns(pool, table_name)
        super(pool, underlying_table(pool, table_name))
      end

      def columns_hash(pool, table_name)
        super(pool, underlying_table(pool, table_name))
      end

      def indexes(pool, table_name)
        super(pool, underlying_table(pool, table_name))
      end

      private

      def underlying_table(pool, table_name)
        renamed_tables_cache(pool).fetch(table_name, table_name)
      end

      def renamed_tables_cache(pool)
        @renamed_tables ||= pool.with_connection do |connection|
          Gitlab::Database::TABLES_TO_BE_RENAMED.select do |old_name, _new_name|
            connection.view_exists?(old_name)
          end
        end
      end

      def clear_renamed_tables_cache!
        @renamed_tables = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables -- needed for memoization
      end
    end
  end
end
