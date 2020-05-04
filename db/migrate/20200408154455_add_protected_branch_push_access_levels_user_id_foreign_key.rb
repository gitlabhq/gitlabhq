# frozen_string_literal: true

class AddProtectedBranchPushAccessLevelsUserIdForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CONSTRAINT_NAME = 'fk_protected_branch_push_access_levels_user_id'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_foreign_key(:protected_branch_push_access_levels, :users, on_delete: :cascade, validate: false, name: CONSTRAINT_NAME)
      remove_foreign_key_if_exists(:protected_branch_push_access_levels, column: :user_id, on_delete: nil)
    end
  end

  def down
    fk_exists = foreign_key_exists?(:protected_branch_push_access_levels, :users, column: :user_id, on_delete: nil)

    unless fk_exists
      with_lock_retries do
        add_foreign_key(:protected_branch_push_access_levels, :users, column: :user_id, validate: false)
      end
    end

    remove_foreign_key_if_exists(:protected_branch_push_access_levels, column: :user_id, name: CONSTRAINT_NAME)

    fk_name = concurrent_foreign_key_name(:protected_branch_push_access_levels, :user_id, prefix: 'fk_rails_')
    validate_foreign_key(:protected_branch_push_access_levels, :user_id, name: fk_name)
  end
end
