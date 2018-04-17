class CreateCiJobTraceChunks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_job_trace_chunks, id: :bigserial do |t|
      t.integer :job_id, null: false
      t.integer :chunk_index, null: false
      t.integer :data_store, null: false
      t.text :raw_data

      t.foreign_key :ci_builds, column: :job_id, on_delete: :cascade
      t.index [:job_id, :chunk_index], unique: true
    end
  end
end
