# frozen_string_literal: true

class SwapWorkItemParentLinksTable < ClickHouse::Migration
  def up
    safe_table_swap('siphon_work_item_parent_links', 'siphon_work_item_parent_links_tmp')

    execute 'DROP VIEW IF EXISTS siphon_work_item_parent_links_tmp_mv'
  end

  def down
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

    safe_table_swap('siphon_work_item_parent_links', 'siphon_work_item_parent_links_tmp')
  end
end
