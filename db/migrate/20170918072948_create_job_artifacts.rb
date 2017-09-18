class CreateJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_job_artifacts do |t|
      t.belongs_to :project, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.integer :job_id, null: false, index: true
      t.integer :size, limit: 8
      t.integer :file_type, null: false, index: true

      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false

      t.string :file

      t.foreign_key :ci_builds, column: :job_id, on_delete: :cascade
    end
  end
end
