# frozen_string_literal: true

class AddSchemaVersionToZoektRepository < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    add_column :zoekt_repositories, :schema_version, :smallint, null: false, default: 0
  end
end
