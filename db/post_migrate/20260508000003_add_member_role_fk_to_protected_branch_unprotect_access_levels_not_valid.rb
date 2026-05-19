# frozen_string_literal: true

# See https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/work_items/28912
class AddMemberRoleFkToProtectedBranchUnprotectAccessLevelsNotValid < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :protected_branch_unprotect_access_levels,
      :member_roles,
      column: :member_role_id,
      on_delete: :restrict,
      validate: false
    )
  end

  def down
    remove_foreign_key_if_exists :protected_branch_unprotect_access_levels, column: :member_role_id
  end
end
