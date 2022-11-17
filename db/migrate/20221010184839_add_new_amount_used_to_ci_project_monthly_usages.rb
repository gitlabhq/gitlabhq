# frozen_string_literal: true

class AddNewAmountUsedToCiProjectMonthlyUsages < Gitlab::Database::Migration[2.0]
  TABLE = :ci_project_monthly_usages
  OLD_COLUMN = :amount_used
  NEW_COLUMN = :new_amount_used
  TRIGGER_NAME = 'sync_projects_amount_used_columns'

  disable_ddl_transaction!

  def up
    check_trigger_permissions!(TABLE)

    add_column(TABLE, NEW_COLUMN, :decimal, default: 0.0, precision: 18, scale: 4, null: false, if_not_exists: true)

    install_rename_triggers(TABLE, OLD_COLUMN, NEW_COLUMN, trigger_name: TRIGGER_NAME)
  end

  def down
    remove_rename_triggers(TABLE, TRIGGER_NAME)

    remove_column(TABLE, NEW_COLUMN)
  end
end
