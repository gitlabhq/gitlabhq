# frozen_string_literal: true

class RemovePushRuleIdFromSiphonNamespaces < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_namespaces DROP COLUMN IF EXISTS push_rule_id;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_namespaces ADD COLUMN IF NOT EXISTS push_rule_id Nullable(Int64);
    SQL
  end
end
