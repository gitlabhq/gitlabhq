# frozen_string_literal: true

class ValidateForeignKeyOnCiBuildTraceChunkPartitionIdBuildId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_build_trace_chunks
  FK_NAME = :fk_rails_1013b761f2_p
  PARTITION_COLUMN = :partition_id
  COLUMN = :build_id

  def up
    validate_foreign_key(TABLE_NAME, [PARTITION_COLUMN, COLUMN], name: FK_NAME)
  end

  def down
    # no-op
  end
end
