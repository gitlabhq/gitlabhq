# frozen_string_literal: true

class AddTraversalIdsToSiphonIssues < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_issues ADD COLUMN namespace_traversal_ids Array(Int64) DEFAULT [];
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_issues DROP COLUMN namespace_traversal_ids;
    SQL
  end
end
