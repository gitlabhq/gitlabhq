# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ClickHouse siphon tables', :click_house, feature_category: :database do
  let_it_be(:siphon_table_prefix) { 'siphon_' }
  let_it_be(:skip_tables) { [] } # insert table name in the array to be skipped on specs
  let_it_be(:skip_fields) { [] } # insert field name in the array to be skipped on specs
  let_it_be(:ch_database_name) { ClickHouse::Client.configuration.databases[:main].database }
  let_it_be(:pg_type_map) { Gitlab::ClickHouse::SiphonGenerator::PG_TYPE_MAP }

  let(:siphon_tables) { ch_table_names - skip_tables }

  it 'has corresponding PG tables', :aggregate_failures do
    siphon_tables.each do |ch_table|
      pg_table = ch_table.sub(siphon_table_prefix, "")

      aggregate_failures "Testing table #{ch_table}" do
        expect(ch_table).to be_a_siphon_of(pg_table)
      end
    end
  end

  RSpec::Matchers.define :be_a_siphon_of do |pg_table|
    match do |ch_table|
      matching_field_names_and_type?(pg_table, ch_table)
    end
  end

  def matching_field_names_and_type?(pg_table, ch_table)
    ch_table_fields = ch_table_fields_hash_for(ch_table)

    pg_table_fields_array_for(pg_table).each do |field_name, type_id|
      next if skip_fields.include?(field_name)

      ch_field_type = ch_table_fields[field_name]

      unless ch_field_type.present?
        raise "Postgres field '#{field_name}' of table '#{pg_table}' is not present in ClickHouse"
      end

      next if ch_field_type.include?(pg_type_map[type_id])

      raise("Postgres field '#{field_name}' of table #{pg_table} does not  " \
        "have the same correspondent type in ClickHouse. Expected #{ch_field_type}, got #{pg_type_map[type_id]}"
           )
    end

    true
  end

  def ch_table_names
    query =
      <<~SQL
        SELECT name
        FROM system.tables
        WHERE database = '#{ch_database_name}';
      SQL

    ::ClickHouse::Client.select(query, :main).filter_map do |row|
      row['name'] if row['name'].start_with?(siphon_table_prefix)
    end
  end

  def ch_table_fields_hash_for(ch_table)
    query =
      <<~SQL
        SELECT name, type
        FROM system.columns
        WHERE table = '#{ch_table}' AND database = '#{ch_database_name}';
      SQL

    result = ClickHouse::Client.select(query, :main)

    result.each_with_object({}) do |row, hash|
      hash[row["name"].to_sym] = row["type"]
    end.with_indifferent_access
  end

  def pg_table_fields_array_for(pg_table)
    sql =
      <<~SQL
          SELECT
              column_name AS field_name,
              pg_type.oid AS field_type_id
          FROM
              information_schema.columns
          JOIN
              pg_catalog.pg_type ON pg_catalog.pg_type.typname = information_schema.columns.udt_name
          WHERE
              table_name = '#{pg_table}';
      SQL

    ApplicationRecord.connection.execute(sql).map(&:values)
  end
end
