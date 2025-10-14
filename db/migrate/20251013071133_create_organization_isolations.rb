# frozen_string_literal: true

class CreateOrganizationIsolations < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    create_table :organization_isolations do |t|
      t.bigint :organization_id, null: false
      t.timestamps_with_timezone null: false
      t.boolean :isolated, null: false, default: false

      t.index :organization_id, unique: true
      t.foreign_key :organizations, column: :organization_id, on_delete: :cascade
    end
  end
end
