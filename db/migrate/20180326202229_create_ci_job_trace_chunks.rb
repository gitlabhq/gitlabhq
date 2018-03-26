class CreateCiJobTraceChunks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_job_trace_chunks do |t|
      t.integer :job_id, null: false
      t.integer :chunk_index, null: false
      t.text :data

      t.foreign_key :ci_builds, column: :job_id, on_delete: :cascade
      t.index [:chunk_index, :job_id], unique: true
    end
  end
end
