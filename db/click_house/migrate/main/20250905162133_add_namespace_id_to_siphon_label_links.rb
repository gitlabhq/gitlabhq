# frozen_string_literal: true

class AddNamespaceIdToSiphonLabelLinks < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_label_links ADD COLUMN namespace_id Int64;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_label_links DROP COLUMN namespace_id;
    SQL
  end
end
