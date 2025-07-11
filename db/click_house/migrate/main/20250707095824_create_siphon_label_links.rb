# frozen_string_literal: true

class CreateSiphonLabelLinks < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_label_links
      (
        id Int64,
        label_id Nullable(Int64),
        target_id Nullable(Int64),
        target_type Nullable(String),
        created_at DateTime64(6, 'UTC') DEFAULT now(),
        updated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_label_links
    SQL
  end
end
