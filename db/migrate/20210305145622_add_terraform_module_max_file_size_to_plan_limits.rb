# frozen_string_literal: true

class AddTerraformModuleMaxFileSizeToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, :terraform_module_max_file_size, :bigint, default: 1.gigabyte, null: false
  end
end
