# frozen_string_literal: true

class AddVerificationStateToCiPipelineArtifact < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_table(:ci_pipeline_artifacts, bulk: true) do |t|
      t.column :verification_started_at, :datetime_with_timezone
      t.column :verification_retry_at, :datetime_with_timezone
      t.column :verified_at, :datetime_with_timezone
      t.integer :verification_state, default: 0, limit: 2, null: false
      t.integer :verification_retry_count, limit: 2
      t.binary :verification_checksum, using: 'verification_checksum::bytea'

      t.text :verification_failure # rubocop:disable Migration/AddLimitToTextColumns
    end
  end
end
