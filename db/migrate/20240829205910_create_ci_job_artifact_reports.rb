# frozen_string_literal: true

class CreateCiJobArtifactReports < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    create_table(:p_ci_job_artifact_reports,
      primary_key: [:job_artifact_id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)', if_not_exists: true) do |t|
      t.bigint :job_artifact_id, null: false
      t.bigint :partition_id, null: false
      t.bigint :project_id, null: false, index: true
      t.integer :status, null: false, limit: 2
      t.text :validation_error, limit: 255
    end
  end

  def down
    drop_table :p_ci_job_artifact_reports
  end
end
