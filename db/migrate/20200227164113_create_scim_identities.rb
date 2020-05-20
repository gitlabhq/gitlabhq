# frozen_string_literal: true

class CreateScimIdentities < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :scim_identities do |t|
      t.references :group, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false
      t.references :user, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone
      t.boolean :active, default: false
      t.string :extern_uid, null: false, limit: 255

      t.index 'LOWER(extern_uid),group_id', name: 'index_scim_identities_on_lower_extern_uid_and_group_id', unique: true
      t.index [:user_id, :group_id], unique: true
    end
  end
  # rubocop:enable Migration/PreventStrings
end
