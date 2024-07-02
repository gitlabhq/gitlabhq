# frozen_string_literal: true

class ValidateAsyncFkOnPCiBuildsAutoCanceledByPartitionId < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  TABLE_NAME = :p_ci_builds
  FK_NAME = :fk_a2141b1522_p
  COLUMNS = [:auto_canceled_by_partition_id, :auto_canceled_by_id]

  def up
    prepare_partitioned_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    unprepare_partitioned_async_foreign_key_validation(TABLE_NAME, COLUMNS, name: FK_NAME)
  end
end
