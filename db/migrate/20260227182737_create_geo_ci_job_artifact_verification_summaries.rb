# frozen_string_literal: true

class CreateGeoCiJobArtifactVerificationSummaries < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    create_table :geo_ci_job_artifact_verification_summaries do |t|
      t.integer :bucket_number, null: false
      t.integer :total_count, default: 0, null: false
      t.integer :verified_count, default: 0, null: false
      t.integer :failed_count, default: 0, null: false
      t.integer :state, limit: 2, default: 0, null: false
      t.datetime_with_timezone :last_calculated_at
      t.datetime_with_timezone :state_changed_at, null: false
      t.timestamps_with_timezone null: false

      t.index :bucket_number, unique: true, name: 'idx_geo_ci_job_artifact_verification_summaries_on_bucket'
      t.index :state, where: 'state IN (1, 2)', name: 'idx_geo_ci_job_artifact_verification_summaries_on_state'
    end
  end
end
