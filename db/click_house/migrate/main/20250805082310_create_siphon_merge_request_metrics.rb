# frozen_string_literal: true

class CreateSiphonMergeRequestMetrics < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_merge_request_metrics
      (
        merge_request_id Int64,
        latest_build_started_at Nullable(DateTime64(6, 'UTC')),
        latest_build_finished_at Nullable(DateTime64(6, 'UTC')),
        first_deployed_to_production_at Nullable(DateTime64(6, 'UTC')),
        merged_at Nullable(DateTime64(6, 'UTC')),
        created_at DateTime64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC'),
        merged_by_id Nullable(Int64),
        latest_closed_by_id Nullable(Int64),
        latest_closed_at Nullable(DateTime64(6, 'UTC')),
        first_comment_at Nullable(DateTime64(6, 'UTC')),
        first_commit_at Nullable(DateTime64(6, 'UTC')),
        last_commit_at Nullable(DateTime64(6, 'UTC')),
        diff_size Nullable(Int64),
        modified_paths_size Nullable(Int64),
        commits_count Nullable(Int64),
        first_approved_at Nullable(DateTime64(6, 'UTC')),
        first_reassigned_at Nullable(DateTime64(6, 'UTC')),
        added_lines Nullable(Int64),
        removed_lines Nullable(Int64),
        target_project_id Nullable(Int64),
        id Int64,
        first_contribution Bool DEFAULT false,
        pipeline_id Nullable(Int64),
        reviewer_first_assigned_at Nullable(DateTime64(6, 'UTC')),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (merge_request_id, id)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_merge_request_metrics
    SQL
  end
end
