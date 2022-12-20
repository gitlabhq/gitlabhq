# frozen_string_literal: true

class ValidateForeignKeyOnCiUnitTestFailurePartitionIdBuildId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_unit_test_failures
  FK_NAME = :fk_0f09856e1f_p
  PARTITION_COLUMN = :partition_id
  COLUMN = :build_id

  def up
    validate_foreign_key(TABLE_NAME, [PARTITION_COLUMN, COLUMN], name: FK_NAME)
  end

  def down
    # no-op
  end
end
