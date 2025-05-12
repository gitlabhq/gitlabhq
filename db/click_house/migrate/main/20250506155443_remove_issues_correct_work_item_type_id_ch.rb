# frozen_string_literal: true

class RemoveIssuesCorrectWorkItemTypeIdCh < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_issues DROP COLUMN IF EXISTS correct_work_item_type_id
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_issues ADD COLUMN IF NOT EXISTS correct_work_item_type_id Int64
    SQL
  end
end
