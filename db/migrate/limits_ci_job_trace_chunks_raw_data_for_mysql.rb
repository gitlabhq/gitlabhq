class LimitsCiJobTraceChunksRawDataForMysql < ActiveRecord::Migration
  def up
    return unless Gitlab::Database.mysql?

    change_column :ci_job_trace_chunks, :raw_data, :text, limit: 16.megabytes - 1 #MEDIUMTEXT
  end
end
