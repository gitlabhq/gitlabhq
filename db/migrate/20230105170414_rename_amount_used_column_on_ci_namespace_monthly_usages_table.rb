# frozen_string_literal: true

class RenameAmountUsedColumnOnCiNamespaceMonthlyUsagesTable < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  TRIGGER_NAME = 'sync_namespaces_amount_used_columns'
  def up
    rename_column :ci_namespace_monthly_usages, :amount_used, :tmp_amount_used
    rename_column :ci_namespace_monthly_usages, :new_amount_used, :amount_used
    rename_column :ci_namespace_monthly_usages, :tmp_amount_used, :new_amount_used

    remove_rename_triggers(:ci_namespace_monthly_usages, TRIGGER_NAME)
    install_rename_triggers(:ci_namespace_monthly_usages, :amount_used, :new_amount_used, trigger_name: TRIGGER_NAME)
  end

  def down
    rename_column :ci_namespace_monthly_usages, :amount_used, :tmp_amount_used
    rename_column :ci_namespace_monthly_usages, :new_amount_used, :amount_used
    rename_column :ci_namespace_monthly_usages, :tmp_amount_used, :new_amount_used

    remove_rename_triggers(:ci_namespace_monthly_usages, TRIGGER_NAME)
    install_rename_triggers(:ci_namespace_monthly_usages, :amount_used, :new_amount_used, trigger_name: TRIGGER_NAME)
  end
end
