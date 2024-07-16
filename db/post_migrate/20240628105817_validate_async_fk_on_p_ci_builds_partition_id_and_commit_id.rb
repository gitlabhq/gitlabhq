# frozen_string_literal: true

class ValidateAsyncFkOnPCiBuildsPartitionIdAndCommitId < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  TABLE_NAME = :p_ci_builds
  FK_NAME = :fk_d3130c9a7f_p
  COLUMNS = [:partition_id, :commit_id]

  def up
    prepare_partitioned_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    unprepare_partitioned_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end
end
