# frozen_string_literal: true

class PrepareAsyncMemberRoleFkOnProtectedBranchMergeAccessLevels < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  FK_NAME = :fk_c0c9525ab9

  def up
    prepare_async_foreign_key_validation :protected_branch_merge_access_levels, :member_role_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :protected_branch_merge_access_levels, :member_role_id, name: FK_NAME
  end
end
