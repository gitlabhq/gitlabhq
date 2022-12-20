# frozen_string_literal: true

class RemoveConstraintsFromCiResourcesForPartitionId < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    change_column_null :ci_resources, :partition_id, true
  end

  def down
    # no-op
    # Adding back the not null constraint requires a long exclusive lock.
    # Also depending on when it gets called, it might not even be possible to
    # execute because the application could have inserted null values.
  end
end
