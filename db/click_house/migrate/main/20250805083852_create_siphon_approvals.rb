# frozen_string_literal: true

class CreateSiphonApprovals < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_approvals
      (
        id Int64,
        merge_request_id Int64,
        user_id Int64,
        created_at DateTime64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC'),
        patch_id_sha String DEFAULT '',
        project_id Int64,
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (merge_request_id, id)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_approvals
    SQL
  end
end
