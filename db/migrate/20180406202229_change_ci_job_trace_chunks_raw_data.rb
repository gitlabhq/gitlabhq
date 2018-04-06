class ChangeCiJobTraceChunksRawData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    
    change_column :ci_job_trace_chunks, :raw_data, :text, limit: 2147483647
  end
end
