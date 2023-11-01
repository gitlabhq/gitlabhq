# frozen_string_literal: true

module Gitlab
  module Database
    # This is a legacy extension targeted at Rails versions prior to 7.1
    # In Rails 7.1, the method parameters have been changed to (connection, table_name)
    module SchemaCacheWithRenamedTableLegacy
      # Override methods in ActiveRecord::ConnectionAdapters::SchemaCache

      def clear!
        super

        clear_renamed_tables_cache!
      end

      def clear_data_source_cache!(name)
        super(name)

        clear_renamed_tables_cache!
      end

      def primary_keys(table_name)
        super(underlying_table(table_name))
      end

      def columns(table_name)
        super(underlying_table(table_name))
      end

      def columns_hash(table_name)
        super(underlying_table(table_name))
      end

      def indexes(table_name)
        super(underlying_table(table_name))
      end

      private

      def underlying_table(table_name)
        renamed_tables_cache.fetch(table_name, table_name)
      end

      def renamed_tables_cache
        @renamed_tables ||= Gitlab::Database::TABLES_TO_BE_RENAMED.select do |old_name, _new_name|
          connection.view_exists?(old_name)
        end
      end

      def clear_renamed_tables_cache!
        @renamed_tables = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end
