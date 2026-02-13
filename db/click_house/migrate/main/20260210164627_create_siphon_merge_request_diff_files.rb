# frozen_string_literal: true

class CreateSiphonMergeRequestDiffFiles < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_merge_request_diff_files
      (
        merge_request_diff_id Int64 CODEC(DoubleDelta, ZSTD),
        relative_order Int64 CODEC(DoubleDelta, ZSTD),
        new_file Bool CODEC(ZSTD(1)),
        renamed_file Bool CODEC(ZSTD(1)),
        deleted_file Bool CODEC(ZSTD(1)),
        too_large Bool CODEC(ZSTD(1)),
        a_mode String,
        b_mode String,
        new_path Nullable(String),
        old_path String,
        diff Nullable(String),
        binary Nullable(Bool) CODEC(ZSTD(1)),
        external_diff_offset Nullable(Int64),
        external_diff_size Nullable(Int64),
        generated Nullable(Bool) CODEC(ZSTD(1)),
        encoded_file_path Bool DEFAULT false CODEC(ZSTD(1)),
        project_id Nullable(Int64),
        traversal_path String DEFAULT multiIf(
          coalesce(project_id, 0) != 0,
          dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', project_id, '0/'),
          '0/'
        ) CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY merge_request_diff_id, relative_order
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, merge_request_diff_id, relative_order)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild';
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_merge_request_diff_files
    SQL
  end
end
