# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join(
  'db/click_house/post_migrate/main/20260319162957_drop_ci_finished_pipelines_aggregation_shadow_tables.rb'
)

RSpec.describe DropCiFinishedPipelinesAggregationShadowTables, :click_house, feature_category: :fleet_visibility do
  let_it_be(:connection) { ::ClickHouse::Connection.new(:main) }

  let(:migration) { described_class.new(connection) }

  def table_exists?(table_name)
    query = ClickHouse::Client::Query.new(
      raw_query: "SELECT count() AS c FROM system.tables " \
        "WHERE database = currentDatabase() AND name = '#{table_name}'"
    )
    connection.select(query).first['c'] > 0
  end

  context 'when running up' do
    before do
      # Ensure shadow tables exist
      %w[ci_finished_pipelines_daily_new ci_finished_pipelines_hourly_new].each do |table|
        connection.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS #{table}
          (
            `path` String DEFAULT '0/',
            `status` LowCardinality(String) DEFAULT '',
            `source` LowCardinality(String) DEFAULT '',
            `ref` String DEFAULT '',
            `started_at_bucket` DateTime64(6, 'UTC') DEFAULT now64(),
            `count_pipelines` AggregateFunction(count),
            `duration_quantile` AggregateFunction(quantile, UInt64),
            `name` String DEFAULT ''
          )
          ENGINE = AggregatingMergeTree()
          ORDER BY (started_at_bucket, path, status, source, ref)
        SQL
      end
    end

    it 'drops the shadow tables' do
      expect(table_exists?('ci_finished_pipelines_daily_new')).to be true
      expect(table_exists?('ci_finished_pipelines_hourly_new')).to be true

      migration.up

      expect(table_exists?('ci_finished_pipelines_daily_new')).to be false
      expect(table_exists?('ci_finished_pipelines_hourly_new')).to be false
    end
  end

  context 'when running down' do
    before do
      connection.execute("DROP TABLE IF EXISTS ci_finished_pipelines_daily_new")
      connection.execute("DROP TABLE IF EXISTS ci_finished_pipelines_hourly_new")
    end

    after do
      connection.execute("DROP TABLE IF EXISTS ci_finished_pipelines_daily_new")
      connection.execute("DROP TABLE IF EXISTS ci_finished_pipelines_hourly_new")
    end

    it 'recreates the shadow tables' do
      expect(table_exists?('ci_finished_pipelines_daily_new')).to be false
      expect(table_exists?('ci_finished_pipelines_hourly_new')).to be false

      migration.down

      expect(table_exists?('ci_finished_pipelines_daily_new')).to be true
      expect(table_exists?('ci_finished_pipelines_hourly_new')).to be true
    end
  end
end
