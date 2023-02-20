# frozen_string_literal: true

class ValidateFkOnCiBuildNeedsPartitionIdAndBuildId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_build_needs
  FK_NAME = :fk_rails_3cf221d4ed_p
  COLUMNS = [:partition_id, :build_id]

  def up
    validate_foreign_key(TABLE_NAME, COLUMNS, name: FK_NAME)
  end

  def down
    # no-op
  end
end
