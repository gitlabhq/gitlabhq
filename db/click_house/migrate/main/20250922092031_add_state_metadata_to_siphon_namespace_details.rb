# frozen_string_literal: true

class AddStateMetadataToSiphonNamespaceDetails < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_namespace_details ADD COLUMN state_metadata String DEFAULT '{}'
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_namespace_details DROP COLUMN state_metadata;
    SQL
  end
end
