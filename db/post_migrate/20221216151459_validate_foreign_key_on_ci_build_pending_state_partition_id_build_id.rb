# frozen_string_literal: true

class ValidateForeignKeyOnCiBuildPendingStatePartitionIdBuildId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = :ci_build_pending_states
  FK_NAME = :fk_rails_0bbbfeaf9d_p
  PARTITION_COLUMN = :partition_id
  COLUMN = :build_id

  def up
    validate_foreign_key(TABLE_NAME, [PARTITION_COLUMN, COLUMN], name: FK_NAME)
  end

  def down
    # no-op
  end
end
