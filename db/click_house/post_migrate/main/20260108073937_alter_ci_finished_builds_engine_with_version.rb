# frozen_string_literal: true

class AlterCiFinishedBuildsEngineWithVersion < ClickHouse::Migration
  def up
    create_tmp_table("ReplacingMergeTree(version, deleted)")
    attach_partitions
    exchange_tables
    drop_tmp_table
  end

  def down
    needs_rollback = engine_full.include?('version, deleted')

    drop_tmp_table

    return unless needs_rollback

    create_tmp_table("ReplacingMergeTree")
    attach_partitions
    exchange_tables
    drop_tmp_table
  end

  private

  # Clone ci_finished_builds into ci_finished_builds_tmp, preserving columns
  # and projections, while swapping the engine.
  #
  # Using `CREATE TABLE ... AS source_table ENGINE = ...` keeps the tmp table
  # structurally identical to the live table regardless of which columns or
  # projections earlier-running regular migrations have added. This is required
  # because post-deployment migrations are deferred on Self-Managed upgrades,
  # so later-timestamped regular migrations may have already added columns by
  # the time this migration runs (see https://gitlab.com/gitlab-org/gitlab/-/work_items/593129).
  #
  # PARTITION BY and ORDER BY are restated explicitly because ClickHouse 23.x
  # and 24.x do not inherit them from the source table in this CREATE form,
  # raising `Code: 36 BAD_ARGUMENTS` without an explicit ORDER BY. They are
  # stable across versions and match the source table by construction, so
  # restating them is safe.
  #
  # `drop_tmp_table` is called first so a previous interrupted run (which
  # could have left ci_finished_builds_tmp behind with stale data or a
  # different schema) does not silently slip past `CREATE TABLE IF NOT EXISTS`
  # and corrupt the subsequent ATTACH PARTITION step. The tmp table never
  # contains data that isn't also still in the source table, so dropping it
  # is safe.
  def create_tmp_table(engine)
    drop_tmp_table

    settings = "index_granularity = 8192, use_async_block_ids_cache = true"
    settings += ", deduplicate_merge_projection_mode = 'rebuild'" if supports_deduplicate_merge_projection_mode?

    execute <<~SQL
      CREATE TABLE ci_finished_builds_tmp AS ci_finished_builds
        ENGINE = #{engine}
        PARTITION BY toYear(finished_at)
        ORDER BY (status, runner_type, project_id, finished_at, id)
        SETTINGS #{settings};
    SQL
  end

  def exchange_tables
    safe_table_swap('ci_finished_builds', 'ci_finished_builds_tmp', '_old')
  end

  # `max_table_size_to_drop = 0` overrides the server-side safety threshold
  # (default 50 GB) so dropping a large tmp table is allowed. This is only
  # valid as a query-level setting on ClickHouse 24.0+. On CH 23.x the same
  # setting is server-level only and raises `UNKNOWN_SETTING` if used
  # inline. On those versions we detach every partition first (`DETACH
  # PARTITION` is not subject to the size check) and then `DROP TABLE` an
  # empty table, which always passes the check.
  def drop_tmp_table
    if supports_max_table_size_to_drop_setting?
      execute 'DROP TABLE IF EXISTS ci_finished_builds_tmp SETTINGS max_table_size_to_drop = 0'
    else
      detach_tmp_partitions
      execute 'DROP TABLE IF EXISTS ci_finished_builds_tmp'
    end
  end

  def detach_tmp_partitions
    return unless connection.table_exists?('ci_finished_builds_tmp')

    partitions_query = <<~SQL
      SELECT DISTINCT partition_id
      FROM system.parts
      WHERE table = 'ci_finished_builds_tmp' AND active
    SQL

    connection.select(partitions_query).pluck('partition_id').each do |partition_id|
      execute("ALTER TABLE ci_finished_builds_tmp DETACH PARTITION ID '#{partition_id}'")
    end
  end

  def attach_partitions
    fetch_partitions.each do |partition|
      execute("ALTER TABLE ci_finished_builds_tmp ATTACH PARTITION #{partition} FROM ci_finished_builds")
    end
  end

  def fetch_partitions
    partitions_query = <<~SQL
      SELECT _partition_id AS partition
      FROM ci_finished_builds
      GROUP BY partition
    SQL

    connection.select(partitions_query).pluck('partition').sort
  end

  def engine_full
    engine_query = <<~SQL
      SELECT engine_full FROM system.tables WHERE name = 'ci_finished_builds';
    SQL
    connection.select(engine_query).pick('engine_full')
  end

  # `deduplicate_merge_projection_mode` was added in ClickHouse 24.8.
  # Earlier 24.x versions report `UNKNOWN_SETTING` if it is used at
  # storage level. Setting it on CH 24.0-24.7 is therefore unsafe even
  # though those versions are not in the GitLab CI matrix; some
  # self-managed customers do run them.
  def supports_deduplicate_merge_projection_mode?
    major, minor = clickhouse_version_major_minor
    return false unless major

    (major == 24 && minor >= 8) || major >= 25
  end

  def supports_max_table_size_to_drop_setting?
    major, _minor = clickhouse_version_major_minor
    return false unless major

    major >= 24
  end

  def clickhouse_version_major_minor
    @clickhouse_version_major_minor ||= begin
      version_string = connection.select(
        ClickHouse::Client::Query.new(raw_query: 'SELECT version() AS version')
      ).pick('version')

      if version_string
        parts = version_string.split('.').first(2).map(&:to_i)
        [parts[0], parts.fetch(1, 0)]
      else
        [nil, nil]
      end
    end
  end
end
