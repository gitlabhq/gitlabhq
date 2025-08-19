# frozen_string_literal: true

class CreateVirtualRegistriesContainerRegistries < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  TABLE_NAME = :virtual_registries_container_registries
  INDEX_NAME = 'virtual_registries_container_registries_on_unique_group_ids'

  def up
    create_table TABLE_NAME, if_not_exists: true do |t|
      t.references :group,
        null: false,
        index: false,
        foreign_key: { to_table: :namespaces, on_delete: :cascade }

      t.timestamps_with_timezone null: false
      t.text :name, limit: 255, null: false
      t.text :description, limit: 1024

      t.index [:group_id, :name], unique: true, name: INDEX_NAME
    end
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
