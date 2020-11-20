# frozen_string_literal: true

class ChangeTerraformVersioningEnabledDefault < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_column_default :terraform_states, :versioning_enabled, from: false, to: true
  end
end
