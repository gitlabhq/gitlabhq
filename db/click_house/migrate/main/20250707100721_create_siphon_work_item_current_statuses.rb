# frozen_string_literal: true

class CreateSiphonWorkItemCurrentStatuses < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_work_item_current_statuses
      (
        id Int64,
        namespace_id Int64,
        work_item_id Int64,
        system_defined_status_id Int64,
        custom_status_id Int64,
        updated_at DateTime64(6, 'UTC'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (work_item_id, id)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_work_item_current_statuses
    SQL
  end
end
