# frozen_string_literal: true

class CreateSiphonIssueAssignees < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_issue_assignees
      (
        user_id Int64,
        issue_id Int64,
        namespace_id Int64,
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (issue_id, user_id)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_issue_assignees
    SQL
  end
end
