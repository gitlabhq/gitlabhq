# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join(
  'db/click_house/post_migrate/main/20260223162956_rebuild_ci_finished_pipelines_aggregation_tables.rb'
)

RSpec.describe RebuildCiFinishedPipelinesAggregationTables, :click_house, :freeze_time, feature_category: :fleet_visibility do
  let_it_be(:connection) { ::ClickHouse::Connection.new(:main) }

  let(:migration) { described_class.new(connection) }
  let(:test_date) { Time.zone.today - 1.month }

  def create_shadow_tables
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
      connection.execute("TRUNCATE TABLE #{table}")
    end
  end

  def cleanup_shadow_tables
    %w[ci_finished_pipelines_daily_new ci_finished_pipelines_hourly_new].each do |table|
      connection.execute("DROP TABLE IF EXISTS #{table}")
    end
    create_shadow_tables
  end

  def get_aggregated_results(table)
    query = ClickHouse::Client::Query.new(
      raw_query: "SELECT path, status, source, ref, name, started_at_bucket, " \
        "countMerge(count_pipelines) AS count_pipelines, " \
        "quantileMerge(duration_quantile) AS duration_quantile " \
        "FROM #{table} " \
        "GROUP BY path, status, source, ref, name, started_at_bucket " \
        "ORDER BY started_at_bucket, path, status"
    )
    connection.select(query)
  end

  def table_row_count(table)
    query = ClickHouse::Client::Query.new(raw_query: "SELECT count() AS c FROM #{table}")
    connection.select(query).first['c']
  end

  before do
    connection.execute("TRUNCATE TABLE ci_finished_pipelines")
    connection.execute("TRUNCATE TABLE ci_finished_pipelines_daily")
    connection.execute("TRUNCATE TABLE ci_finished_pipelines_hourly")
    create_shadow_tables
  end

  after do
    cleanup_shadow_tables
  end

  context 'with data containing duplicates' do
    before do
      connection.execute(
        <<~SQL
          INSERT INTO ci_finished_pipelines
            (id, path, status, source, ref, name, started_at, finished_at, duration)
          VALUES
            (1, '1/2/3/', 'success', 'push', 'main', 'pipeline', toDateTime64('#{test_date} 10:00:00', 6, 'UTC'), toDateTime64('#{test_date} 10:30:00', 6, 'UTC'), 1800),
            (1, '1/2/3/', 'success', 'push', 'main', 'pipeline', toDateTime64('#{test_date} 10:00:00', 6, 'UTC'), toDateTime64('#{test_date} 10:30:00', 6, 'UTC'), 1800),
            (2, '1/2/3/', 'failed', 'schedule', 'develop', 'pipeline-2', toDateTime64('#{test_date} 14:00:00', 6, 'UTC'), toDateTime64('#{test_date} 14:30:00', 6, 'UTC'), 1800)
        SQL
      )
    end

    it 'deduplicates and swaps both daily and hourly tables' do
      migration.up

      # Daily results: id=1 appears twice but should be deduplicated to count as 1
      daily_results = get_aggregated_results('ci_finished_pipelines_daily')
      expect(daily_results.size).to eq(2)
      expect(daily_results).to all(include('count_pipelines' => 1))

      # Hourly results: same deduplication
      hourly_results = get_aggregated_results('ci_finished_pipelines_hourly')
      expect(hourly_results.size).to eq(2)
      expect(hourly_results).to all(include('count_pipelines' => 1))
    end
  end

  context 'with epoch-zero rows' do
    let(:out_of_range_recent_date) { Time.zone.today }
    let(:out_of_range_old_date) { Time.zone.today - 13.months }

    before do
      connection.execute(
        <<~SQL
          INSERT INTO ci_finished_pipelines
            (id, path, status, source, ref, name, started_at, finished_at, duration)
          VALUES
            (10, '1/2/3/', 'success', 'push', 'main', 'pipeline-10', toDateTime64('1970-01-01 00:00:00.000000', 6, 'UTC'), toDateTime64('#{test_date} 10:00:00', 6, 'UTC'), 900),
            (10, '1/2/3/', 'success', 'push', 'main', 'pipeline-10', toDateTime64('1970-01-01 00:00:00.000000', 6, 'UTC'), toDateTime64('#{test_date} 10:00:00', 6, 'UTC'), 900),
            (11, '1/2/3/', 'failed', 'push', 'main', 'pipeline-11', toDateTime64('1970-01-01 00:00:00.000000', 6, 'UTC'), toDateTime64('#{test_date} 11:00:00', 6, 'UTC'), 600),
            (12, '1/2/3/', 'success', 'push', 'main', 'pipeline-12', toDateTime64('1970-01-01 00:00:00.000000', 6, 'UTC'), toDateTime64('#{out_of_range_recent_date} 10:00:00', 6, 'UTC'), 900),
            (13, '1/2/3/', 'success', 'push', 'main', 'pipeline-13', toDateTime64('1970-01-01 00:00:00.000000', 6, 'UTC'), toDateTime64('#{out_of_range_old_date} 10:00:00', 6, 'UTC'), 900)
        SQL
      )
    end

    it 'backfills epoch-zero rows filtered by finished_at and swaps' do
      # id=10 appears twice but should be deduplicated to count as 1 pipeline
      # id=11 is separate, so total unique pipelines = 2
      # id=12 has finished_at on reference_date (excluded by < comparison), so it's excluded
      # id=13 has finished_at older than MONTHS_TO_BACKFILL, so it's excluded
      migration.up

      daily_results = get_aggregated_results('ci_finished_pipelines_daily')
      epoch_results = daily_results.select { |r| r['started_at_bucket'].year == 1970 }
      expect(epoch_results.size).to eq(2)
      expect(epoch_results).to all(include('count_pipelines' => 1))
    end
  end

  context 'with two pipelines in the same bucket' do
    before do
      connection.execute(
        <<~SQL
          INSERT INTO ci_finished_pipelines
            (id, path, status, source, ref, name, started_at, finished_at, duration)
          VALUES
            (20, '1/2/3/', 'success', 'push', 'main', 'pipeline', toDateTime64('#{test_date} 10:00:00', 6, 'UTC'), toDateTime64('#{test_date} 10:30:00', 6, 'UTC'), 1800),
            (21, '1/2/3/', 'success', 'push', 'main', 'pipeline', toDateTime64('#{test_date} 10:15:00', 6, 'UTC'), toDateTime64('#{test_date} 10:45:00', 6, 'UTC'), 1800)
        SQL
      )
    end

    it 'aggregates them into a single row with count 2 and swaps' do
      migration.up

      # Both pipelines have the same path/status/source/ref/name and same daily bucket
      daily_results = get_aggregated_results('ci_finished_pipelines_daily')
      expect(daily_results.size).to eq(1)
      expect(daily_results.first).to include('count_pipelines' => 2)
    end
  end

  context 'when migration is retried after a previous run' do
    before do
      connection.execute(
        <<~SQL
          INSERT INTO ci_finished_pipelines
            (id, path, status, source, ref, name, started_at, finished_at, duration)
          VALUES
            (30, '1/2/3/', 'success', 'push', 'main', 'pipeline', toDateTime64('#{test_date} 10:00:00', 6, 'UTC'), toDateTime64('#{test_date} 10:30:00', 6, 'UTC'), 1800)
        SQL
      )
    end

    it 'does not inflate aggregations' do
      migration.up
      # Swap back so we can run up again
      migration.down

      migration.up

      daily_results = get_aggregated_results('ci_finished_pipelines_daily')
      expect(daily_results.size).to eq(1)
      expect(daily_results.first).to include('count_pipelines' => 1)
    end
  end

  context 'when there is no data' do
    it 'completes without errors and swaps' do
      expect { migration.up }.not_to raise_error
    end

    it 'results in empty live tables' do
      migration.up

      expect(table_row_count('ci_finished_pipelines_daily')).to eq(0)
      expect(table_row_count('ci_finished_pipelines_hourly')).to eq(0)
    end
  end

  context 'when running down' do
    before do
      connection.execute(
        <<~SQL
          INSERT INTO ci_finished_pipelines
            (id, path, status, source, ref, name, started_at, finished_at, duration)
          VALUES
            (60, '1/2/3/', 'success', 'push', 'main', 'pipeline', toDateTime64('#{test_date} 10:00:00', 6, 'UTC'), toDateTime64('#{test_date} 10:30:00', 6, 'UTC'), 1800)
        SQL
      )
    end

    it 'reverses the swap' do
      migration.up

      daily_count_after_up = table_row_count('ci_finished_pipelines_daily')
      hourly_count_after_up = table_row_count('ci_finished_pipelines_hourly')
      expect(daily_count_after_up).to be > 0
      expect(hourly_count_after_up).to be > 0

      migration.down

      # After down, the _new tables should have the data (swapped back from live)
      expect(table_row_count('ci_finished_pipelines_daily_new')).to eq(daily_count_after_up)
      expect(table_row_count('ci_finished_pipelines_hourly_new')).to eq(hourly_count_after_up)
    end
  end
end
