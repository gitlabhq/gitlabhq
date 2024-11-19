# frozen_string_literal: true

class CreateUserMemberRole < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    create_table :user_member_roles do |t|
      t.bigint :user_id, null: false
      t.bigint :member_role_id, null: false

      t.timestamps_with_timezone null: false

      t.index [:user_id], name: 'idx_user_member_roles_on_user_id'
      t.index [:member_role_id], name: 'idx_user_member_roles_on_member_role_id'
    end
  end
end
