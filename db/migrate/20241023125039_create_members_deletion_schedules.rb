# frozen_string_literal: true

class CreateMembersDeletionSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    create_table :members_deletion_schedules do |t|
      t.references :namespace, index: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false
      t.references :user, index: true, foreign_key: { to_table: :users, on_delete: :cascade }, null: false
      t.references :scheduled_by, null: false, index: true, foreign_key: { to_table: :users, on_delete: :cascade }
      t.timestamps_with_timezone null: false

      t.index [:namespace_id, :user_id], unique: true,
        name: 'idx_members_deletion_schedules_on_namespace_id_and_user_id'
    end
  end

  def down
    drop_table :members_deletion_schedules, if_exists: true
  end
end
