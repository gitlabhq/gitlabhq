# frozen_string_literal: true

class PrepareAsyncMemberRoleFkOnProtectedBranchPushAccessLevels < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  FK_NAME = :fk_9778b2c1bb

  def up
    prepare_async_foreign_key_validation :protected_branch_push_access_levels, :member_role_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :protected_branch_push_access_levels, :member_role_id, name: FK_NAME
  end
end
