# frozen_string_literal: true

class RenameAmountUsedColumn < Gitlab::Database::Migration[2.1]
  TRIGGER_NAME = 'sync_projects_amount_used_columns'
  def up
    rename_column :ci_project_monthly_usages, :amount_used, :tmp_amount_used
    rename_column :ci_project_monthly_usages, :new_amount_used, :amount_used
    rename_column :ci_project_monthly_usages, :tmp_amount_used, :new_amount_used

    remove_rename_triggers(:ci_project_monthly_usages, TRIGGER_NAME)
    install_rename_triggers(:ci_project_monthly_usages, :amount_used, :new_amount_used, trigger_name: TRIGGER_NAME)
  end

  def down
    rename_column :ci_project_monthly_usages, :amount_used, :tmp_amount_used
    rename_column :ci_project_monthly_usages, :new_amount_used, :amount_used
    rename_column :ci_project_monthly_usages, :tmp_amount_used, :new_amount_used

    remove_rename_triggers(:ci_project_monthly_usages, TRIGGER_NAME)
    install_rename_triggers(:ci_project_monthly_usages, :amount_used, :new_amount_used, trigger_name: TRIGGER_NAME)
  end
end
