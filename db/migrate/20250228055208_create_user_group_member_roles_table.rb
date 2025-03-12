# frozen_string_literal: true

class CreateUserGroupMemberRolesTable < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  INDEX_NAME = 'unique_user_group_member_roles_all_ids'
  INDEX_COLUMNS = %i[user_id group_id shared_with_group_id member_role_id]

  def change
    create_table :user_group_member_roles do |t|
      t.bigint :user_id, null: false, index: false
      t.bigint :group_id, null: false, index: true
      t.bigint :shared_with_group_id, null: true, index: true
      t.bigint :member_role_id, null: false, index: true
      t.timestamps_with_timezone null: false
      t.index INDEX_COLUMNS, name: INDEX_NAME, unique: true
    end
  end
end
