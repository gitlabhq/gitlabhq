class CreateCiJobTraceChunks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_job_trace_chunks, id: :bigserial do |t|
      t.integer :job_id, null: false
      t.integer :chunk_index, null: false
      t.integer :data_store, null: false
      # Mysql needs MEDIUMTEXT type (up to 16MB) rather than TEXT (up to 64KB)
      # Because 'raw_data' is always capped by Ci::JobTraceChunk::CHUNK_SIZE, which is 128KB
      t.text :raw_data, limit: 16.megabytes - 1

      t.foreign_key :ci_builds, column: :job_id, on_delete: :cascade
      t.index [:job_id, :chunk_index], unique: true
    end
  end
end
