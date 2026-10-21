# frozen_string_literal: true

class ValidateNotNullMergeAfterToMergeSchedules < Gitlab::Database::Migration[2.4]
  disable_ddl_transaction!

  milestone '19.6'

  def up
    validate_not_null_constraint :merge_request_merge_schedules, :merge_after
  end

  def down
    # no-op: can't make the constraint not valid again.
    # Would be pointless anyway as a not valid constraint still blocks new records violating it.
  end
end
