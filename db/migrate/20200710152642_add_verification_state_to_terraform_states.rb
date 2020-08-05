# frozen_string_literal: true

class AddVerificationStateToTerraformStates < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_table(:terraform_states) do |t|
      t.column :verification_retry_at, :datetime_with_timezone
      t.column :verified_at, :datetime_with_timezone
      t.integer :verification_retry_count, limit: 2
      t.binary :verification_checksum, using: 'verification_checksum::bytea'

      # rubocop:disable Migration/AddLimitToTextColumns
      # limit is added in 20200710153009_add_verification_failure_limit_and_index_to_terraform_states
      t.text :verification_failure
      # rubocop:enable Migration/AddLimitToTextColumns
    end
  end
end
