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
  def create_tmp_table(engine)
    settings = "index_granularity = 8192, use_async_block_ids_cache = true"
    settings += ", deduplicate_merge_projection_mode = 'rebuild'" if supports_deduplicate_merge_projection_mode?

    execute <<~SQL
      CREATE TABLE IF NOT EXISTS ci_finished_builds_tmp AS ci_finished_builds
        ENGINE = #{engine}
        PARTITION BY toYear(finished_at)
        ORDER BY (status, runner_type, project_id, finished_at, id)
        SETTINGS #{settings};
    SQL
  end

  def exchange_tables
    safe_table_swap('ci_finished_builds', 'ci_finished_builds_tmp', '_old')
  end

  def drop_tmp_table
    execute 'DROP TABLE IF EXISTS ci_finished_builds_tmp SETTINGS max_table_size_to_drop = 0'
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

  def supports_deduplicate_merge_projection_mode?
    version_query = <<~SQL
      SELECT version() AS version;
    SQL
    version_string = connection.select(version_query).pick('version')

    return false unless version_string

    version_parts = version_string.split('.').first(3).map(&:to_i)
    major = version_parts[0]
    minor = version_parts[1]

    (major == 24 && minor >= 1) || major >= 25
  end
end
