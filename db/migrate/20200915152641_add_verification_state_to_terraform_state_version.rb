# frozen_string_literal: true

class AddVerificationStateToTerraformStateVersion < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_table(:terraform_state_versions) do |t|
      t.integer :verification_retry_count, limit: 2
      t.column :verification_retry_at, :datetime_with_timezone
      t.column :verified_at, :datetime_with_timezone
      t.binary :verification_checksum, using: 'verification_checksum::bytea'

      # rubocop:disable Migration/AddLimitToTextColumns
      t.text :verification_failure
      # rubocop:enable Migration/AddLimitToTextColumns
    end
  end
end
