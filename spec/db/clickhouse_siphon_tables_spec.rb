# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ClickHouse siphon tables', feature_category: :database do
  let_it_be(:siphon_table_prefix) { 'siphon_' }
  let_it_be(:skip_tables) { [] } # insert table name in the array to be skipped on specs
  let_it_be(:skip_fields) do
    # insert field names to be skipped on specs
    # traversal_path: computed column only in ClickHouse
    # users table: sensitive/auth fields intentionally excluded from siphon
    %(
      title_html
      description_html
      traversal_path
      confirmation_sent_at
      confirmation_token
      confirmed_at
      encrypted_otp_secret
      encrypted_otp_secret_iv
      encrypted_otp_secret_salt
      encrypted_password
      feed_token
      incoming_email_token
      lock_version
      note_html
      otp_backup_codes
      otp_required_for_login
      otp_secret_expires_at
      password_expires_at
      remember_created_at
      reset_password_sent_at
      reset_password_token
      static_object_token
      static_object_token_encrypted
      unlock_token
      cached_markdown_version
      secrets
      id_tokens
      model_metadata_json
      flow_metadata_json
    )
  end

  let_it_be(:ch_schema) { ClickHouse::SchemaCache[:main] }
  let_it_be(:pg_type_map) { Gitlab::ClickHouse::SiphonGenerator::PG_TYPE_MAP }
  let_it_be(:ch_type_map) { pg_type_map.invert }

  let(:siphon_tables) { siphon_table_names - skip_tables }

  it 'has corresponding PG tables', :aggregate_failures do
    siphon_tables.each do |ch_table|
      pg_table = ch_table.sub(siphon_table_prefix, "")

      aggregate_failures "Testing table #{ch_table}" do
        expect(ch_table).to be_a_siphon_of(pg_table)
      end
    end
  end

  describe 'Siphon definition' do
    let(:clickhouse_table_names) { ch_table_names.to_set }
    let(:skip_ignore_columns) do
      {
        'namespaces' => %w[max_personal_access_token_lifetime],
        'users' => %w[otp_secret_expires_at]
      }
    end

    Dir[Rails.root.join("db/siphon/tables/*.yml")].each do |file|
      it "has correct configuration for #{File.basename(file, '.yml')}", :aggregate_failures do
        content = YAML.safe_load_file(file)
        table = content['table']

        if content['renamed_table_name']
          # Without the pin, the NATS subject follows `table` and the rename orphans the stream
          expect(content['original_table_name']).to be_present,
            "'renamed_table_name' requires 'original_table_name' to pin the NATS subject"
        end

        pg_table = existing_pg_table(content)
        expect(pg_table).to be_present,
          "none of #{pg_table_candidates(content).join(', ')} exist in PostgreSQL"
        next unless pg_table

        expect(content).to have_correct_replication_target(clickhouse_table_names, pg_table)

        # Partitions have no db/docs entry of their own, the parent table's config covers these checks
        next unless schema_for(content) == 'public'

        table_config = YAML.safe_load_file(docs_path_for(content))

        expect(content).to match_database_schema(table_config)
        expect(content).to ignore_sensitive_and_encrypted_columns(table_config, skip_ignore_columns[table])
        expect(content).to have_correct_reconcile_config(table_config)
      end
    end
  end

  describe 'configuration helpers' do
    describe '#schema_for' do
      it 'defaults to the public schema' do
        expect(schema_for({ 'table' => 'labels' })).to eq('public')
      end

      it 'returns the configured schema' do
        expect(schema_for({ 'table' => 'labels', 'schema' => 'gitlab_partitions_dynamic' }))
          .to eq('gitlab_partitions_dynamic')
      end
    end

    describe '#existing_pg_table' do
      it 'prefers the table over the renamed table' do
        content = { 'table' => 'labels', 'renamed_table_name' => 'milestones' }

        expect(existing_pg_table(content)).to eq('public.labels')
      end

      it 'falls back to the renamed table' do
        content = { 'table' => 'not_renamed_yet', 'renamed_table_name' => 'labels' }

        expect(existing_pg_table(content)).to eq('public.labels')
      end

      it 'qualifies the table with the configured schema' do
        content = { 'table' => 'labels', 'schema' => 'gitlab_partitions_dynamic' }

        expect(existing_pg_table(content)).to be_nil
      end

      it 'returns nil when no candidate exists' do
        expect(existing_pg_table({ 'table' => 'not_renamed_yet' })).to be_nil
      end
    end

    describe '#docs_path_for' do
      it 'falls back to the documentation of the renamed table' do
        content = { 'table' => 'not_renamed_yet', 'renamed_table_name' => 'labels' }

        expect(docs_path_for(content)).to eq(Rails.root.join("db/docs/labels.yml"))
      end

      it 'returns the path of the table when no documentation exists' do
        expect(docs_path_for({ 'table' => 'not_renamed_yet' }))
          .to eq(Rails.root.join("db/docs/not_renamed_yet.yml"))
      end
    end
  end

  def schema_for(content)
    content['schema'] || 'public'
  end

  # `table` may not exist yet (or any more) while a table rename is in flight, so
  # `renamed_table_name` is accepted as an alternative.
  def pg_table_candidates(content)
    [content['table'], content['renamed_table_name']].compact.map { |table| "#{schema_for(content)}.#{table}" }
  end

  def existing_pg_table(content)
    pg_table_candidates(content).find { |identifier| ApplicationRecord.connection.table_exists?(identifier) }
  end

  def docs_path_for(content)
    [content['table'], content['renamed_table_name']].compact
      .map { |table| Rails.root.join('db', 'docs', "#{table}.yml") }
      .find { |path| File.exist?(path) } || Rails.root.join('db', 'docs', "#{content['table']}.yml")
  end

  def matching_field_names_and_type?(pg_table, ch_table)
    ch_table_fields = ch_table_fields_hash_for(ch_table)

    pg_table_fields_array_for(pg_table).each do |field_name, type_id|
      next if skip_fields.include?(field_name)

      ch_field_type = ch_table_fields[field_name]

      unless ch_field_type.present?
        raise "This table is synchronised to ClickHouse and you've added a new column! " \
          "Missing ClickHouse field '#{field_name}' for table '#{pg_table}'. " \
          "Create a ClickHouse migration to add this field. " \
          "See: https://docs.gitlab.com/development/database/clickhouse/clickhouse_within_gitlab/#handling-siphon-errors-in-tests"
      end

      next if ch_field_type.include?(pg_type_map[type_id])

      # Using Int8 can be allowed for smallint (Int16) PG columns
      # in cases when the ActiveRecord ENUM contains only a few values.
      next if ch_field_type.include?('Int8') && type_id == ch_type_map['Int16']

      raise("Postgres field '#{field_name}' of table #{pg_table} does not  " \
        "have the same correspondent type in ClickHouse. Expected #{ch_field_type}, got #{pg_type_map[type_id]}"
           )
    end

    true
  end

  def siphon_table_names
    ch_table_names.select { |name| name.start_with?(siphon_table_prefix) }
  end

  def ch_table_names
    ch_schema.table_names
  end

  def ch_table_fields_hash_for(ch_table)
    ch_schema.columns(ch_table)
      .to_h { |column| [column.name, column.type] }
      .with_indifferent_access
  end

  # Used by the `have_correct_replication_target` matcher (delegated via method_missing).
  def ch_column_names(ch_table)
    ch_schema.columns(ch_table).map(&:name)
  end

  # Used by the `have_correct_replication_target` matcher (delegated via method_missing).
  def ch_primary_keys(ch_table)
    table = ch_schema.table(ch_table)
    raise "Table not found: #{ch_table}" unless table

    table.primary_key.map { |column| column.is_a?(ClickHouse::SchemaCache::Column) ? column.name : column }
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
