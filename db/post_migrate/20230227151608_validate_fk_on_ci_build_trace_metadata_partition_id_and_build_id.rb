# frozen_string_literal: true

class ValidateFkOnCiBuildTraceMetadataPartitionIdAndBuildId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_build_trace_metadata
  FK_NAME = :fk_rails_aebc78111f_p
  COLUMNS = [:partition_id, :build_id]

  def up
    validate_foreign_key(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    # no-op
  end
end
