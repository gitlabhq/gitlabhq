# frozen_string_literal: true

class ValidateMemberRoleFkOnProtectedBranchUnprotectAccessLevels < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  FK_NAME = :fk_6fd290f6a3

  def up
    validate_foreign_key :protected_branch_unprotect_access_levels, :member_role_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
