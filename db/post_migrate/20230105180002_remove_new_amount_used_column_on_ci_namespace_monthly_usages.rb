# frozen_string_literal: true

class RemoveNewAmountUsedColumnOnCiNamespaceMonthlyUsages < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  TRIGGER_NAME = 'sync_namespaces_amount_used_columns'
  def up
    remove_rename_triggers :ci_namespace_monthly_usages, TRIGGER_NAME
    remove_column :ci_namespace_monthly_usages, :new_amount_used
  end

  def down
    return if column_exists?(:ci_namespace_monthly_usages, :new_amount_used)

    # rubocop:disable Migration/SchemaAdditionMethodsNoPost, Migration/AddColumnsToWideTables
    add_column :ci_namespace_monthly_usages, :new_amount_used, :decimal, default: 0.0,
                                                                       precision: 18, scale: 2, null: false
    # rubocop:enable Migration/SchemaAdditionMethodsNoPost, Migration/AddColumnsToWideTables

    install_rename_triggers :ci_namespace_monthly_usages, :amount_used, :new_amount_used, trigger_name: TRIGGER_NAME
  end
end
