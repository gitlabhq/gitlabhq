# frozen_string_literal: true

class AddVerificationStateAndStartedAtToTerraformStateVersionTable < ActiveRecord::Migration[6.0]
  def change
    change_table(:terraform_state_versions) do |t|
      t.column :verification_started_at, :datetime_with_timezone
      t.integer :verification_state, default: 0, limit: 2, null: false
    end
  end
end
