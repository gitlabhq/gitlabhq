# frozen_string_literal: true

class ReplaceWorkItemTypeBackfillNextBatchStrategy < Gitlab::Database::Migration[1.0]
  def up
    # no-op
    # migrations will be rescheduled with the correct batching class
    # no need for this migration
  end

  def down
    # no-op
  end
end
