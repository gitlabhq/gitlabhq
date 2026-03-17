# frozen_string_literal: true

# Backfill shadow tables with deduplicated data from ci_finished_pipelines,
# then atomically swap them into place using EXCHANGE TABLES.
#
# Like all ClickHouse migrations, this runs under ExclusiveLock, which pauses
# sync workers and ensures no new data arrives during the backfill + swap.
# Estimated runtime: ~2 minutes on GitLab.com (235 batches * ~0.5s each).
#
# See https://gitlab.com/gitlab-org/gitlab/-/issues/586319
class RebuildCiFinishedPipelinesAggregationTables < ClickHouse::Migration
  MONTHS_TO_BACKFILL = 12
  SOURCE_TABLE = 'ci_finished_pipelines'
  SOURCE_TIMESTAMP_COLUMN = 'started_at'

  # Rows with this value have no real started_at (the pipeline was never started
  # or the value was not recorded). We handle these separately, filtering by
  # finished_at instead.
  EPOCH_ZERO = '1970-01-01 00:00:00.000000'

  # Process source rows in id-range batches to keep ClickHouse memory usage
  # bounded. A single unbatched INSERT ... SELECT can require significant
  # memory; batching by id range keeps each query small.
  ID_BATCH_SIZE = 10_000_000

  TABLES = [
    { target: 'ci_finished_pipelines_daily_new',
      live: 'ci_finished_pipelines_daily',
      interval: 'toIntervalDay(1)' },
    { target: 'ci_finished_pipelines_hourly_new',
      live: 'ci_finished_pipelines_hourly',
      interval: 'toIntervalHour(1)' }
  ].freeze

  def up
    reference_date = fetch_reference_date_from_clickhouse
    oldest_date = (reference_date - MONTHS_TO_BACKFILL.months).beginning_of_month

    TABLES.each do |table_config|
      backfill_and_swap(table_config, reference_date, oldest_date)
    end
  end

  def down
    TABLES.reverse_each do |table_config|
      safe_table_swap(table_config[:target], table_config[:live])
    end
  end

  private

  def backfill_and_swap(table_config, reference_date, oldest_date)
    target = table_config[:target]

    # Truncate to ensure idempotency: if a previous run failed mid-way
    # and is retried, already-inserted batches would otherwise inflate aggregations.
    execute("TRUNCATE TABLE #{target}")

    write "Backfilling #{target} with data from #{oldest_date} to #{reference_date}..."

    backfill_recent_data(table_config, oldest_date, reference_date)
    backfill_epoch_rows(table_config, oldest_date, reference_date)

    write "Swapping #{table_config[:live]} with #{target}..."
    safe_table_swap(target, table_config[:live])
  end

  def backfill_recent_data(table_config, oldest_date, reference_date)
    write "  Backfilling rows with #{SOURCE_TIMESTAMP_COLUMN} in #{oldest_date} to #{reference_date}..."

    insert_batched(
      "#{SOURCE_TIMESTAMP_COLUMN} >= '#{oldest_date}' AND #{SOURCE_TIMESTAMP_COLUMN} < '#{reference_date}'",
      table_config
    )
  end

  def backfill_epoch_rows(table_config, oldest_date, reference_date)
    write "  Backfilling epoch-zero rows with finished_at in #{oldest_date} to #{reference_date}..."

    insert_batched(
      "#{SOURCE_TIMESTAMP_COLUMN} = '#{EPOCH_ZERO}' " \
        "AND finished_at >= '#{oldest_date}' AND finished_at < '#{reference_date}'",
      table_config
    )
  end

  def insert_batched(filter, table_config)
    min_id, max_id = get_table_id_bounds
    return write "    No source data in table, skipping." if min_id.nil?

    batch_count = 0

    (min_id..max_id).step(ID_BATCH_SIZE) do |batch_start|
      batch_end = [batch_start + ID_BATCH_SIZE - 1, max_id].min
      where_clause = "id >= #{batch_start} AND id <= #{batch_end} AND #{filter}"
      batch_count += 1

      execute(<<~SQL)
        INSERT INTO #{table_config[:target]}
        #{select_statement(where_clause, table_config[:interval])}
      SQL
    end

    write "    Completed in #{batch_count} batch(es)."
  end

  def select_statement(where_clause, interval_func)
    <<~SQL.chomp
      SELECT
        any_path AS path,
        any_status AS status,
        any_source AS source,
        any_ref AS ref,
        toStartOfInterval(any_started_at, #{interval_func}) AS started_at_bucket,
        countState() AS count_pipelines,
        quantileState(any_duration) AS duration_quantile,
        any_name AS name
      FROM (
        SELECT
          any(path) AS any_path,
          any(status) AS any_status,
          any(source) AS any_source,
          any(ref) AS any_ref,
          any(started_at) AS any_started_at,
          any(duration) AS any_duration,
          any(name) AS any_name
        FROM #{SOURCE_TABLE}
        WHERE #{where_clause}
        GROUP BY id
      )
      GROUP BY any_path, any_status, any_source, any_ref, started_at_bucket, any_name
    SQL
  end

  def select_single(raw_query)
    query = ClickHouse::Client::Query.new(raw_query: raw_query)
    connection.select(query).first
  end

  def get_table_id_bounds
    result = select_single("SELECT min(id) AS min_id, max(id) AS max_id FROM #{SOURCE_TABLE}")
    return [nil, nil] if result.nil? || result['min_id'].nil? || result['min_id'] == 0

    result.values_at('min_id', 'max_id')
  end

  def fetch_reference_date_from_clickhouse
    result = select_single('SELECT today() AS reference_date')
    raise ClickHouse::MigrationSupport::Errors::Base, 'Failed to fetch reference date from ClickHouse' if result.nil?

    result['reference_date'].to_date
  end
end
