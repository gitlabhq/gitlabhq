# frozen_string_literal: true

class ReplaceSubscriptionUserAddOnAssignmentVersionsOrgFkWithCascade < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  OLD_FK_NAME = :fk_rails_091e013a61
  TABLE_NAME = :subscription_user_add_on_assignment_versions
  COLUMN_NAME = :organization_id
  TARGET_TABLE = :organizations

  def up
    # Remove the existing FK with no ON DELETE clause (defaults to NO ACTION)
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, TARGET_TABLE,
        column: COLUMN_NAME,
        name: OLD_FK_NAME,
        reverse_lock_order: true
    end

    # Add a new FK with ON DELETE CASCADE (validate: false to avoid long lock)
    add_concurrent_foreign_key TABLE_NAME, TARGET_TABLE,
      column: COLUMN_NAME,
      on_delete: :cascade,
      validate: false
  end

  def down
    # Remove the CASCADE FK
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, TARGET_TABLE,
        column: COLUMN_NAME,
        reverse_lock_order: true
    end

    # Restore the original FK with no ON DELETE clause (NO ACTION)
    add_concurrent_foreign_key TABLE_NAME, TARGET_TABLE,
      column: COLUMN_NAME,
      name: OLD_FK_NAME,
      on_delete: nil
  end
end
