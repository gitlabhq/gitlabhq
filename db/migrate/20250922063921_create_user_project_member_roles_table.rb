# frozen_string_literal: true

class CreateUserProjectMemberRolesTable < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def change
    create_table :user_project_member_roles do |t|
      t.timestamps_with_timezone null: false
      t.references :user, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.bigint :project_id, null: false, index: true
      t.bigint :shared_with_group_id, null: true, index: true
      t.bigint :member_role_id, null: false, index: true
    end
  end
end
