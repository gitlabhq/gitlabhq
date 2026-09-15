# frozen_string_literal: true

class AddAllowedInWorkloadsToCiGroupVariables < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :ci_group_variables, :allowed_in_workloads, :boolean, default: false, null: false
  end
end
