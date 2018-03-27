class CreateJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_job_artifacts do |t|
      t.belongs_to :project, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.integer :job_id, null: false
      t.integer :file_type, null: false
      t.integer :size, limit: 8

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.datetime_with_timezone :expire_at

      t.string :file

      t.foreign_key :ci_builds, column: :job_id, on_delete: :cascade
      t.index [:job_id, :file_type], unique: true
    end
  end
end
