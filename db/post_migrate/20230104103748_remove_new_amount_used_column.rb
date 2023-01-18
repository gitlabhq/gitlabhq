# frozen_string_literal: true

class RemoveNewAmountUsedColumn < Gitlab::Database::Migration[2.1]
  TRIGGER_NAME = 'sync_projects_amount_used_columns'
  def up
    remove_rename_triggers :ci_project_monthly_usages, TRIGGER_NAME
    remove_column :ci_project_monthly_usages, :new_amount_used
  end

  def down
    return if column_exists?(:ci_project_monthly_usages, :new_amount_used)

    # rubocop:disable Migration/SchemaAdditionMethodsNoPost, Migration/AddColumnsToWideTables
    add_column :ci_project_monthly_usages, :new_amount_used, :decimal, default: 0.0,
                                                                       precision: 18, scale: 2, null: false
    # rubocop:enable Migration/SchemaAdditionMethodsNoPost, Migration/AddColumnsToWideTables

    install_rename_triggers :ci_project_monthly_usages, :amount_used, :new_amount_used, trigger_name: TRIGGER_NAME
  end
end
