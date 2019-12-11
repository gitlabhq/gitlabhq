# frozen_string_literal: true

class UpdateGroupDeletionSchedulesForeignKeys < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:group_deletion_schedules, :users, column: :user_id, on_delete: :cascade, name: new_foreign_key_name)
    remove_foreign_key_if_exists(:group_deletion_schedules, column: :user_id, on_delete: :nullify)
  end

  def down
    add_concurrent_foreign_key(:group_deletion_schedules, :users, column: :user_id, on_delete: :nullify, name: existing_foreign_key_name)
    remove_foreign_key_if_exists(:group_deletion_schedules, column: :user_id, on_delete: :cascade)
  end

  private

  def new_foreign_key_name
    concurrent_foreign_key_name(:group_deletion_schedules, :user_id)
  end

  def existing_foreign_key_name
    'fk_group_deletion_schedules_users_user_id'
  end
end
