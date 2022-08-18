# frozen_string_literal: true

class RemoveCiNamespaceMonthlyUsagesAdditionalAmountAvailableColumn < Gitlab::Database::Migration[2.0]
  def up
    remove_column :ci_namespace_monthly_usages, :additional_amount_available
  end

  def down
    add_column :ci_namespace_monthly_usages, :additional_amount_available, :integer, default: 0, null: false
  end
end
