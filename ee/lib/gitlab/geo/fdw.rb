module Gitlab
  module Geo
    module Fdw
      DEFAULT_SCHEMA = 'public'.freeze
      FDW_SCHEMA = 'gitlab_secondary'.freeze

      # Return full table name with FDW schema
      #
      # @param [String] table_name
      def self.table(table_name)
        FDW_SCHEMA + ".#{table_name}"
      end

      # Return if FDW is enabled for this instance
      #
      # @return [Boolean] whether FDW is enabled
      def self.enabled?
        return false unless fdw_capable?

        # FDW is enabled by default, disable it by setting `fdw: false` in config/database_geo.yml
        value = Rails.configuration.geo_database['fdw']
        value.nil? ? true : value
      end

      def self.fdw_capable?
        has_foreign_schema? && connection_exist? && count_tables.positive?
      end

      def self.fdw_up_to_date?
        has_foreign_schema? && foreign_schema_tables_match?
      end

      def self.has_foreign_schema?
        Gitlab::Geo.cache_value(:geo_fdw_schema_exist) do
          sql = <<~SQL
            SELECT 1
              FROM information_schema.schemata
             WHERE schema_name='#{FDW_SCHEMA}'
          SQL

          ::Geo::TrackingBase.connection.execute(sql).count.positive?
        end
      end

      # Check if there is at least one FDW connection configured
      #
      # @return [Boolean] whether any FDW connection exists
      def self.connection_exist?
        ::Geo::TrackingBase.connection.execute(
          "SELECT 1 FROM pg_foreign_server"
        ).count.positive?
      end

      # Number of existing tables
      #
      # @return [Integer] number of tables
      def self.count_tables
        Gitlab::Geo.cache_value(:geo_fdw_count_tables) do
          sql = <<~SQL
            SELECT COUNT(*)
              FROM information_schema.tables
             WHERE table_schema = '#{FDW_SCHEMA}'
               AND table_type = 'FOREIGN TABLE'
               AND table_name NOT LIKE 'pg_%'
          SQL

          ::Geo::TrackingBase.connection.execute(sql).first.fetch('count').to_i
        end
      end

      # Check if foreign schema has exact the same tables and fields defined on secondary database
      #
      # @return [Boolean] whether schemas match and are not empty
      def self.foreign_schema_tables_match?
        Gitlab::Geo.cache_value(:geo_fdw_schema_tables_match) do
          schema = gitlab_schema

          schema.present? && schema == fdw_schema
        end
      end

      def self.count_tables_match?
        gitlab_tables.count == count_tables
      end

      def self.gitlab_tables
        ActiveRecord::Schema.tables.reject { |table| table.start_with?('pg_') }
      end

      def self.gitlab_schema
        retrieve_schema_tables(ActiveRecord::Base, ActiveRecord::Base.connection_config[:database], DEFAULT_SCHEMA).to_a
      end

      def self.fdw_schema
        retrieve_schema_tables(::Geo::TrackingBase, Rails.configuration.geo_database['database'], FDW_SCHEMA).to_a
      end

      def self.retrieve_schema_tables(adapter, database, schema)
        sql = <<~SQL
            SELECT table_name, column_name, data_type
              FROM information_schema.columns
             WHERE table_catalog = '#{database}'
               AND table_schema = '#{schema}'
               AND table_name NOT LIKE 'pg_%'
          ORDER BY table_name, column_name, data_type
        SQL

        adapter.connection.select_all(sql)
      end
      private_class_method :retrieve_schema_tables
    end
  end
end
