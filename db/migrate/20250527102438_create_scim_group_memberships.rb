# frozen_string_literal: true

class CreateScimGroupMemberships < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    create_table :scim_group_memberships do |t|
      t.timestamps_with_timezone null: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.uuid :scim_group_uid, null: false

      t.index :scim_group_uid, name: 'index_scim_group_memberships_on_scim_group_uid'
      t.index [:user_id, :scim_group_uid], name: 'unique_scim_group_memberships_user_id_and_scim_group_uid',
        unique: true
    end
  end
end
