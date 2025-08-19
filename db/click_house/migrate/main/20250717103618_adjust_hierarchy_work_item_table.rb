# frozen_string_literal: true

class AdjustHierarchyWorkItemTable < ClickHouse::Migration
  def up
    execute 'ALTER TABLE hierarchy_work_items DROP COLUMN label_ids'
    execute 'ALTER TABLE hierarchy_work_items DROP COLUMN assignee_ids'
    execute "ALTER TABLE hierarchy_work_items ADD COLUMN label_ids String DEFAULT ''"
    execute "ALTER TABLE hierarchy_work_items ADD COLUMN assignee_ids String DEFAULT ''"
  end

  def down
    execute 'ALTER TABLE hierarchy_work_items DROP COLUMN label_ids'
    execute 'ALTER TABLE hierarchy_work_items DROP COLUMN assignee_ids'
    execute 'ALTER TABLE hierarchy_work_items ADD COLUMN label_ids Array(Int64) DEFAULT []'
    execute 'ALTER TABLE hierarchy_work_items ADD COLUMN assignee_ids Array(Int64) DEFAULT []'
  end
end
