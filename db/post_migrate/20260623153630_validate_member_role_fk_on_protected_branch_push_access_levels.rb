# frozen_string_literal: true

class ValidateMemberRoleFkOnProtectedBranchPushAccessLevels < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  FK_NAME = :fk_9778b2c1bb

  def up
    validate_foreign_key :protected_branch_push_access_levels, :member_role_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
