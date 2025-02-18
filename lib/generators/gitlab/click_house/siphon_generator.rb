# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'

module Gitlab
  module ClickHouse
    class SiphonGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "Generates a migration that creates a table for receiving replicated " \
        "data (using Siphon) from a matching PG table."

      argument :table_name, type: :string, required: true, desc: "The PG table to be cloned"

      # Data types table
      # Postgresql OID reference - https://jdbc.postgresql.org/documentation/publicapi/org/postgresql/core/Oid.html
      PG_TYPE_MAP = {
        16 => 'Bool',
        17 => 'String',
        20 => 'Int64',
        21 => 'Int8',
        23 => 'Int64',
        25 => 'String',
        1016 => 'Array(Int64)',
        1043 => 'String',
        1082 => 'Date32',
        1184 => "DateTime64(6, 'UTC')",
        1114 => "DateTime64(6, 'UTC')"
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
        <<-TEXT.chomp
CREATE TABLE IF NOT EXISTS #{clickhouse_table_name}
      (
      #{table_fields},
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
        TEXT
      end

      def table_fields
        fields =
          pg_fields_metadata.map do |field|
            ch_field_type = ch_type_for(field)

            "#{field['field_name']} #{ch_field_type}"
          end

        <<-TEXT.chomp
  #{fields[0]},
        #{fields[1..].join(",\n        ")}
        TEXT
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
                table_name = '#{table_name}';
        SQL
      end
    end
  end
end
