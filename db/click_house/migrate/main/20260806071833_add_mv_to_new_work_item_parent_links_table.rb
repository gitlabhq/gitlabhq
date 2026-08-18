# frozen_string_literal: true

class AddMvToNewWorkItemParentLinksTable < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS siphon_work_item_parent_links_tmp_mv
      TO siphon_work_item_parent_links_tmp
      AS
      SELECT
        id,
        work_item_id,
        work_item_parent_id,
        relative_position,
        created_at,
        updated_at,
        namespace_id,
        traversal_path,
        _siphon_replicated_at,
        _siphon_deleted
      FROM siphon_work_item_parent_links
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS siphon_work_item_parent_links_tmp_mv'
  end
end
