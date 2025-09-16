# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaCacheWithRenamedTable71
      # Override methods in ActiveRecord::ConnectionAdapters::SchemaCache for Rails 7.1
      # https://github.com/rails/rails/blob/v7.1.5.2/activerecord/lib/active_record/connection_adapters/schema_cache.rb

      def clear!
        super

        clear_renamed_tables_cache!
      end

      def clear_data_source_cache!(connection, table_name)
        super

        clear_renamed_tables_cache!
      end

      def primary_keys(connection, table_name)
        super(connection, underlying_table(connection, table_name))
      end

      def columns(connection, table_name)
        super(connection, underlying_table(connection, table_name))
      end

      def columns_hash(connection, table_name)
        super(connection, underlying_table(connection, table_name))
      end

      def indexes(connection, table_name)
        super(connection, underlying_table(connection, table_name))
      end

      private

      def underlying_table(connection, table_name)
        renamed_tables_cache(connection).fetch(table_name, table_name)
      end

      def renamed_tables_cache(connection)
        @renamed_tables ||= Gitlab::Database::TABLES_TO_BE_RENAMED.select do |old_name, _new_name|
          connection.view_exists?(old_name)
        end
      end

      def clear_renamed_tables_cache!
        @renamed_tables = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables -- needed for memoization
      end
    end
  end
end
