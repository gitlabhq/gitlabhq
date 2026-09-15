# frozen_string_literal: true

class AddProtectedRefToCiWorkloads < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :p_ci_workloads, :protected_ref, :boolean, default: false, null: false
  end
end
