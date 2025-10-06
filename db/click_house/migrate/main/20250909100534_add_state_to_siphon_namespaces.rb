# frozen_string_literal: true

class AddStateToSiphonNamespaces < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_namespaces ADD COLUMN state Int8;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_namespaces DROP COLUMN state;
    SQL
  end
end
