class CreateCiBuildTraceChunks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_build_trace_chunks, id: :bigserial do |t|
      t.integer :build_id, null: false
      t.integer :chunk_index, null: false
      t.integer :data_store, null: false
      t.binary :raw_data

      t.foreign_key :ci_builds, column: :build_id, on_delete: :cascade
      t.index [:build_id, :chunk_index], unique: true
    end
  end
end
