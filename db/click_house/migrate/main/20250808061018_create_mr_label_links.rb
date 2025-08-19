# frozen_string_literal: true

class CreateMrLabelLinks < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS merge_request_label_links
      (
        id Int64,
        label_id Int64,
        merge_request_id Int64,
        created_at DateTime64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC'),
        version DateTime64(6, 'UTC') DEFAULT now(),
        deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY (merge_request_id, label_id, id)
    SQL

    execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS merge_request_label_links_mv
      TO merge_request_label_links
      AS
      SELECT
        id,
        label_id,
        target_id AS merge_request_id,
        created_at,
        updated_at,
        _siphon_replicated_at AS version,
        _siphon_deleted AS deleted
      FROM siphon_label_links
      WHERE
      target_type = 'MergeRequest' AND
      target_id IS NOT NULL AND
      label_id IS NOT NULL
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS merge_request_label_links_mv
    SQL

    execute <<-SQL
      DROP TABLE IF EXISTS merge_request_label_links
    SQL
  end
end
