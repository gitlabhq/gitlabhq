# frozen_string_literal: true

class CreateGroupScimIdentities < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  def change
    create_table :group_scim_identities do |t|
      t.references :group, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false
      t.references :user, index: false, foreign_key: { on_delete: :cascade }, null: false

      t.timestamps_with_timezone null: false
      t.bigint :temp_source_id, index: { unique: true }, comment: 'Temporary column to store scim_idenity id'
      t.boolean :active, default: false
      t.text :extern_uid, limit: 255, null: false

      t.index [:user_id, :group_id], unique: true
      t.index "lower(extern_uid), group_id", unique: true
    end
  end
end
