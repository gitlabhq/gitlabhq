# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('db/click_house/migrate/main/20260713105637_add_siphon_stats_table.rb')
require Rails.root.join('db/click_house/migrate/main/20260921160325_fix_siphon_internal_events_ttl.rb')
require Rails.root.join('db/click_house/migrate/main/20260903114041_create_query_log_usage.rb')
require Rails.root.join('db/click_house/migrate/main/20260921162218_fix_query_log_usage_ttl.rb')
require Rails.root.join('db/click_house/migrate/main/20260914090001_create_merge_requests_base.rb')
require Rails.root.join('db/click_house/migrate/main/20260921162254_fix_merge_requests_base_ttl.rb')

RSpec.describe 'ClickHouse TTL compatibility', click_house: :without_migrations, feature_category: :database do
  let(:connection) { ClickHouse::Connection.new(:main) }

  shared_examples 'a compatible TTL migration' do
    before do
      create_migration.up
      connection.execute("INSERT INTO #{table} (#{column}) VALUES (now64(6, 'UTC'))")
    end

    def table_definition
      connection.select("SHOW CREATE TABLE #{table}").first.fetch('statement')
    end

    it 'converges with fresh installations without rewriting existing data', :aggregate_failures do
      original_definition = table_definition
      original_rows = connection.select("SELECT #{column} FROM #{table}")

      migration.up
      migration.up

      expect(table_definition).to eq(original_definition)
      expect(table_definition).to include("TTL toDateTime(#{column}) + #{interval}")
      expect(connection.select("SELECT #{column} FROM #{table}")).to eq(original_rows)
      expect(connection.select(<<~SQL)).to be_empty
        SELECT mutation_id FROM system.mutations
        WHERE database = currentDatabase() AND table = '#{table}'
      SQL
    end

    it 'normalizes an existing TTL expression', :aggregate_failures do
      connection.execute(<<~SQL)
        ALTER TABLE #{table}
        MODIFY TTL toDateTime(#{column} + #{interval})
        SETTINGS materialize_ttl_after_modify = 0
      SQL

      migration.up

      expect(table_definition).to include("TTL toDateTime(#{column}) + #{interval}")
      expect(connection.select("SELECT count() AS count FROM #{table}").first['count']).to eq(1)
    end

    it 'retains the compatible retention policy on rollback' do
      migration.up
      original_definition = table_definition

      migration.down

      expect(table_definition).to eq(original_definition)
    end
  end

  context 'with Siphon internal events' do
    let(:migration) { FixSiphonInternalEventsTtl.new(connection) }
    let(:create_migration) { AddSiphonStatsTable.new(connection) }
    let(:table) { 'siphon_internal_events' }
    let(:column) { 'timestamp' }
    let(:interval) { 'toIntervalMonth(12)' }

    it_behaves_like 'a compatible TTL migration'
  end

  context 'with query log usage' do
    let(:migration) { FixQueryLogUsageTtl.new(connection) }
    let(:create_migration) { CreateQueryLogUsage.new(connection) }
    let(:table) { 'query_log_usage' }
    let(:column) { 'event_time' }
    let(:interval) { 'toIntervalMonth(3)' }

    it_behaves_like 'a compatible TTL migration'
  end

  context 'with the merge requests buffer' do
    let(:migration) { FixMergeRequestsBaseTtl.new(connection) }
    let(:create_migration) { CreateMergeRequestsBase.new(connection) }
    let(:table) { 'merge_requests_base' }
    let(:column) { 'seen' }
    let(:interval) { 'toIntervalHour(1)' }

    it_behaves_like 'a compatible TTL migration'
  end
end
