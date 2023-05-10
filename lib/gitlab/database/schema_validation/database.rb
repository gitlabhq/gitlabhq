# frozen_string_literal: true

module Gitlab
  module Database
    module SchemaValidation
      class Database
        STATIC_PARTITIONS_SCHEMA = 'gitlab_partitions_static'

        def initialize(connection)
          @connection = connection
        end

        def fetch_index_by_name(index_name)
          index_map[index_name]
        end

        def fetch_trigger_by_name(trigger_name)
          trigger_map[trigger_name]
        end

        def fetch_table_by_name(table_name)
          table_map[table_name]
        end

        def index_exists?(index_name)
          index_map[index_name].present?
        end

        def trigger_exists?(trigger_name)
          trigger_map[trigger_name].present?
        end

        def table_exists?(table_name)
          fetch_table_by_name(table_name).present?
        end

        def indexes
          index_map.values
        end

        def triggers
          trigger_map.values
        end

        def tables
          table_map.values
        end

        private

        attr_reader :connection

        def schemas
          @schemas ||= [STATIC_PARTITIONS_SCHEMA, connection.current_schema]
        end

        def index_map
          @index_map ||=
            fetch_indexes.transform_values! do |index_stmt|
              SchemaObjects::Index.new(PgQuery.parse(index_stmt).tree.stmts.first.stmt.index_stmt)
            end
        end

        def trigger_map
          @trigger_map ||=
            fetch_triggers.transform_values! do |trigger_stmt|
              SchemaObjects::Trigger.new(PgQuery.parse(trigger_stmt).tree.stmts.first.stmt.create_trig_stmt)
            end
        end

        def table_map
          @table_map ||= fetch_tables.transform_values! do |stmt|
            columns = stmt.map { |column| SchemaObjects::Column.new(Adapters::ColumnDatabaseAdapter.new(column)) }

            SchemaObjects::Table.new(stmt.first['table_name'], columns)
          end
        end

        def fetch_indexes
          sql = <<~SQL
            SELECT indexname, indexdef
            FROM pg_indexes
            WHERE indexname NOT LIKE '%_pkey' AND schemaname IN ($1, $2);
          SQL

          connection.select_rows(sql, nil, schemas).to_h
        end

        def fetch_triggers
          sql = <<~SQL
            SELECT triggers.tgname, pg_get_triggerdef(triggers.oid)
            FROM pg_catalog.pg_trigger triggers
            INNER JOIN pg_catalog.pg_class rel ON triggers.tgrelid = rel.oid
            INNER JOIN pg_catalog.pg_namespace nsp ON nsp.oid = rel.relnamespace
            WHERE triggers.tgisinternal IS FALSE
            AND nsp.nspname IN ($1, $2)
          SQL

          connection.select_rows(sql, nil, schemas).to_h
        end

        def fetch_tables
          sql = <<~SQL
            SELECT
              table_information.relname  AS table_name,
              col_information.attname AS column_name,
              col_information.attnotnull AS not_null,
              col_information.attnum = ANY(pg_partitioned_table.partattrs) as partition_key,
              format_type(col_information.atttypid, col_information.atttypmod) AS data_type,
              pg_get_expr(col_default_information.adbin, col_default_information.adrelid) AS column_default
            FROM pg_attribute AS col_information
            JOIN pg_class     AS table_information  ON col_information.attrelid = table_information.oid
            JOIN pg_namespace AS schema_information ON table_information.relnamespace = schema_information.oid
            LEFT JOIN pg_partitioned_table ON pg_partitioned_table.partrelid = table_information.oid
            LEFT JOIN pg_attrdef AS col_default_information ON col_information.attrelid = col_default_information.adrelid
              AND col_information.attnum = col_default_information.adnum
            WHERE NOT col_information.attisdropped
            AND col_information.attnum > 0
            AND table_information.relkind IN ('r', 'p')
            AND schema_information.nspname IN ($1, $2)
          SQL

          connection.exec_query(sql, nil, schemas).group_by { |row| row['table_name'] }
        end
      end
    end
  end
end
