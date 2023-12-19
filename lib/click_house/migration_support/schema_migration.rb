# frozen_string_literal: true

module ClickHouse
  module MigrationSupport
    class SchemaMigration
      def initialize(connection, table_name: 'schema_migrations')
        @connection = connection
        @table_name = table_name
      end

      def ensure_table
        return if connection.table_exists?(table_name)

        query = <<~SQL
          CREATE TABLE #{table_name} (
            version LowCardinality(String),
            active UInt8 NOT NULL DEFAULT 1,
            applied_at DateTime64(6, 'UTC') NOT NULL DEFAULT now64()
          )
          ENGINE = ReplacingMergeTree(applied_at)
          PRIMARY KEY(version)
          ORDER BY (version)
        SQL

        connection.execute(query)
      end

      def all_versions
        query = <<~SQL
          SELECT version FROM #{table_name} FINAL
          WHERE active = 1
          ORDER BY (version)
        SQL

        connection.select(query).pluck('version')
      end

      def create!(**args)
        insert_sql = <<~SQL
          INSERT INTO #{table_name} (#{args.keys.join(',')}) VALUES (#{args.values.join(',')})
        SQL

        connection.execute(insert_sql)
      end

      private

      attr_reader :connection, :table_name
    end
  end
end
