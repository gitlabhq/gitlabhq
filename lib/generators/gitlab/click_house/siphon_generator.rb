# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'

module Gitlab
  module ClickHouse
    class SiphonGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc <<~DESC
        Generates a migration that creates a table for receiving replicated data (using Siphon)
        from a matching PostgreSQL table.

        Example:
          rails generate gitlab:click_house:siphon PG_TABLE_NAME --with-traversal-path

        This will create:
          db/clickhouse/migrate/main/TIMESTAMP_create_siphon_PG_TABLE_NAME.rb
      DESC

      argument :table_name, type: :string, required: true, desc: "The PG table to be cloned"

      class_option :with_traversal_path, type: :boolean, required: false, default: false,
        desc: "Adds an extra `traversal_path` column to the table which will be automatically " \
          "populated based on the configured sharding keys"

      # Data types table
      # Postgresql OID reference - https://jdbc.postgresql.org/documentation/publicapi/org/postgresql/core/Oid.html
      PG_TYPE_MAP = {
        16 => 'Bool',
        17 => 'String',
        20 => 'Int64',
        21 => 'Int16',
        23 => 'Int64',
        25 => 'String',
        869 => 'String', # ip address type
        1016 => 'Array(Int64)',
        1043 => 'String',
        1082 => 'Date32',
        1184 => "DateTime64(6, 'UTC')",
        1114 => "DateTime64(6, 'UTC')",
        3802 => "String" # JSONB
      }.freeze

      # The generator needs to look up traversal_path values from parent entities (organizations,
      # namespaces, or projects).
      # Instead of expensive JOINs, ClickHouse uses dictionaries for O(1) lookups.
      # Organization, Namespace and Project are the only entities that have traversal_ids/traversal_path in PostgreSQL.
      DICTIONARIES = {
        'projects' => 'project_traversal_paths_dict',
        'namespaces' => 'namespace_traversal_paths_dict',
        'organizations' => 'organization_traversal_paths_dict'
      }.freeze

      PG_TO_CH_DEFAULT_MAP = {
        /^nextval/ => ->(default) {
          warn "Sequences like #{default} are not supported in ClickHouse"
          nil
        },
        /^ARRAY\[.*\]::.*$/ => ->(default) {
          warn "Array defaults like (#{default}) are not supported in ClickHouse."
          nil
        },
        /'\{\}'::\w+\[\]/ => ->(_) {
          '[]' # For arrays with empty as default
        },
        'now()' => ->(_) {
          'now()'
        },
        /^\d+(\.\d+)?$/ => ->(default) {
          default # numeric default
        },
        /::.*$/ => ->(default) {
          default.split('::').first # extract string default
        },
        'true' => ->(_) {
          'true'
        },
        'false' => ->(_) {
          'false'
        }
      }.freeze

      def validate!
        return unless pg_fields_metadata.count == 0

        raise ArgumentError, "PG #{table_name} table does not exist"
      end

      def generate_ch_table
        timestamp = Time.current.strftime('%Y%m%d%H%M%S')

        migration_path = "db/click_house/migrate/main/#{timestamp}_create_siphon_#{table_name}.rb"

        template 'siphon_table.rb.template', migration_path
      end

      private

      def clickhouse_table_name
        "siphon_#{table_name}"
      end

      def table_definition
        definitions = [
          *table_columns,
          "_siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1))",
          "_siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1))",
          *table_projection
        ].flatten.compact.join(",\n        ")

        settings_str = table_settings.any? ? "\n      SETTINGS #{table_settings.join(', ')}" : ""

        <<-TEXT.chomp
CREATE TABLE IF NOT EXISTS #{clickhouse_table_name}
      (
        #{definitions}
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (#{primary_keys.join(', ')})#{settings_str}
        TEXT
      end

      def build_traversal_path_field
        db_yml = Rails.root.join('db', 'docs', "#{table_name}.yml")
        raise "Unknown PostgreSQL table, table definition is missing: #{db_yml}" unless File.exist?(db_yml)

        table_yml = YAML.safe_load_file(db_yml)
        raise "No sharding_key definition present for table '#{table_name}'" if Array(table_yml["sharding_key"]).empty?

        conditions = table_yml["sharding_key"].map do |column, parent_table|
          null_to_zero = "coalesce(#{column}, 0)"
          dictionary = DICTIONARIES.fetch(parent_table)
          "#{null_to_zero} != 0, dictGetOrDefault('#{dictionary}', 'traversal_path', #{column}, '0/')"
        end
        conditions << "'0/'"

        "traversal_path String DEFAULT multiIf(#{conditions.join(', ')}) CODEC(ZSTD(3))"
      end

      def primary_keys
        return pg_primary_keys unless hierarchy_denormalization?

        ['traversal_path'] + pg_primary_keys
      end

      def table_columns
        cols = pg_fields_metadata.map do |field|
          [
            field['field_name'],
            ch_type_for(field),
            compression_for(field)
          ].compact.join(' ')
        end

        cols << build_traversal_path_field if hierarchy_denormalization?

        cols
      end

      def table_projection
        return unless hierarchy_denormalization?

        [primary_key_projection]
      end

      def table_settings
        # Lower value is faster for IN queries doing primary key lookups (default: 8192)
        @table_settings ||= ['index_granularity = 2048'].tap do |array|
          array << "deduplicate_merge_projection_mode = 'rebuild'" if hierarchy_denormalization?
        end
      end

      def ch_type_for(pg_field)
        field_oid = pg_field['field_type_id']

        field = PG_TYPE_MAP[field_oid]

        return 'INSERT_CH_TYPE' if field.nil?

        field = "Nullable(#{field})" if pg_field['nullable'] == 'YES'

        field_default = ch_default_for(pg_field['default'])
        field = "#{field} DEFAULT #{field_default}" if field_default

        field
      end

      def ch_default_for(pg_default)
        return if pg_default.nil?

        PG_TO_CH_DEFAULT_MAP.each do |pattern, transformer|
          return transformer.call(pg_default) if pattern === pg_default
        end

        warn "Default expression (#{pg_default}) not compatible with ClickHouse."

        'INSERT_COLUMN_DEFAULT' # Fallback to a placeholder
      end

      def pg_fields_metadata
        @fields_metadata ||= ApplicationRecord.connection.execute <<~SQL
            SELECT
                column_name AS field_name,
                column_default AS default,
                is_nullable AS nullable,
                pg_type.oid AS field_type_id
            FROM
                information_schema.columns
            JOIN
                pg_catalog.pg_type ON pg_catalog.pg_type.typname = information_schema.columns.udt_name
            WHERE
                table_name = '#{table_name}' AND
                table_catalog = '#{ApplicationRecord.connection.current_database}';
        SQL
      end

      def pg_primary_keys
        @pg_primary_keys ||= begin
          primary_keys = ApplicationRecord.connection.execute <<~SQL
                                 SELECT kcu.column_name AS column
                                 FROM
                                     information_schema.table_constraints AS tc
                                 JOIN
                                     information_schema.key_column_usage AS kcu
                                     ON tc.constraint_name = kcu.constraint_name
                                     AND tc.table_schema = kcu.table_schema
                                 WHERE
                                     tc.constraint_type = 'PRIMARY KEY'
                                     AND tc.table_catalog = '#{ApplicationRecord.connection.current_database}'
                                     AND tc.table_name = '#{table_name}'
                                 ORDER BY
                                     kcu.ordinal_position;
          SQL
          primary_keys.pluck('column') # rubocop: disable CodeReuse/ActiveRecord -- getting the primary key values
        end
      end

      def hierarchy_denormalization?
        options['with_traversal_path']
      end

      def primary_key_projection
        primary_keys = pg_primary_keys.join(', ')
        <<-TEXT.chomp
PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY #{primary_keys}
        )
        TEXT
      end

      def compression_for(field)
        ch_type = PG_TYPE_MAP[field['field_type_id']]
        is_pk   = pg_primary_keys.include?(field['field_name'])

        if is_pk
          return 'CODEC(DoubleDelta, ZSTD)' if ch_type.start_with?('Int', 'DateTime64')
          return 'CODEC(ZSTD(3))' if ch_type == 'String'

          return
        end

        # Bool can be compressed in any case
        return 'CODEC(ZSTD(1))' if ch_type == 'Bool'

        return 'CODEC(Delta, ZSTD(1))' if field['field_name'] == 'created_at' || field['field_name'] == 'updated_at'

        nil
      end
    end
  end
end
