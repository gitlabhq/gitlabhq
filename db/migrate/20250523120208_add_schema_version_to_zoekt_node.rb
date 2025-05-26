# frozen_string_literal: true

class AddSchemaVersionToZoektNode < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :zoekt_nodes, :schema_version, :smallint, null: false, default: 0
  end
end
