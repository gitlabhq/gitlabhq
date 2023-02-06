# frozen_string_literal: true

class ValidateFkOnCiResourcesPartitionIdAndBuildId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_resources
  FK_NAME = :fk_e169a8e3d5_p
  COLUMNS = [:partition_id, :build_id]

  def up
    validate_foreign_key(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    # no-op
  end
end
