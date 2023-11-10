# frozen_string_literal: true

module ClickHouse
  module MigrationSupport
    class SchemaMigration
      class_attribute :table_name_prefix, instance_writer: false, default: ''
      class_attribute :table_name_suffix, instance_writer: false, default: ''
      class_attribute :schema_migrations_table_name, instance_accessor: false, default: 'schema_migrations'

      class << self
        TABLE_EXISTS_QUERY = <<~SQL.squish
          SELECT 1 FROM system.tables
          WHERE name = {table_name: String} AND database = {database_name: String}
        SQL

        def primary_key
          'version'
        end

        def table_name
          "#{table_name_prefix}#{schema_migrations_table_name}#{table_name_suffix}"
        end

        def table_exists?(database, configuration = ClickHouse::Migration.client_configuration)
          database_name = configuration.databases[database]&.database
          return false unless database_name

          placeholders = { table_name: table_name, database_name: database_name }
          query = ClickHouse::Client::Query.new(raw_query: TABLE_EXISTS_QUERY, placeholders: placeholders)

          ClickHouse::Client.select(query, database, configuration).any?
        end

        def create_table(database, configuration = ClickHouse::Migration.client_configuration)
          return if table_exists?(database, configuration)

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

          ClickHouse::Client.execute(query, database, configuration)
        end

        def all_versions(database)
          query = <<~SQL
            SELECT version FROM #{table_name} FINAL
            WHERE active = 1
            ORDER BY (version)
          SQL

          ClickHouse::Client.select(query, database, ClickHouse::Migration.client_configuration).pluck('version')
        end

        def create!(database, **args)
          insert_sql = <<~SQL
            INSERT INTO #{table_name} (#{args.keys.join(',')}) VALUES (#{args.values.join(',')})
          SQL

          ClickHouse::Client.execute(insert_sql, database, ClickHouse::Migration.client_configuration)
        end
      end
    end
  end
end
