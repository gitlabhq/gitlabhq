# frozen_string_literal: true

class ValidateMemberRoleFkOnProtectedBranchMergeAccessLevels < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  FK_NAME = :fk_c0c9525ab9

  def up
    validate_foreign_key :protected_branch_merge_access_levels, :member_role_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
