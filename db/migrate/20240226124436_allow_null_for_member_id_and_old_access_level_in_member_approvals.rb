# frozen_string_literal: true

class AllowNullForMemberIdAndOldAccessLevelInMemberApprovals < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.10'

  def change
    change_column_null :member_approvals, :member_id, true
    change_column_null :member_approvals, :old_access_level, true
  end
end
