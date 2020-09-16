# frozen_string_literal: true

class AddVersioningEnabledToTerraformStates < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :terraform_states, :versioning_enabled, :boolean, null: false, default: false
  end
end
