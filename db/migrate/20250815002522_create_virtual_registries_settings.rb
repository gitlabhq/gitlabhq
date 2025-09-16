# frozen_string_literal: true

class CreateVirtualRegistriesSettings < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  TABLE_NAME = :virtual_registries_settings

  def change
    create_table TABLE_NAME do |t|
      t.references :group, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade },
        index: { unique: true }
      t.timestamps_with_timezone null: false
      t.boolean :enabled, default: false, null: false
    end
  end
end
