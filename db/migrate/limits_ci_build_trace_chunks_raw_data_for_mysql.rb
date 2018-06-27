class LimitsCiBuildTraceChunksRawDataForMysql < ActiveRecord::Migration
  def up
    return unless Gitlab::Database.mysql?

    # Mysql needs MEDIUMTEXT type (up to 16MB) rather than TEXT (up to 64KB)
    # Because 'raw_data' is always capped by Ci::BuildTraceChunk::CHUNK_SIZE, which is 128KB
    change_column :ci_build_trace_chunks, :raw_data, :binary, limit: 16.megabytes - 1 #MEDIUMTEXT
  end
end
