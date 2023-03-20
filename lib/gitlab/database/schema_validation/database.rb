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

        def index_exists?(index_name)
          index_map[index_name].present?
        end

        def trigger_exists?(trigger_name)
          trigger_map[trigger_name].present?
        end

        def indexes
          index_map.values
        end

        def triggers
          trigger_map.values
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
      end
    end
  end
end
