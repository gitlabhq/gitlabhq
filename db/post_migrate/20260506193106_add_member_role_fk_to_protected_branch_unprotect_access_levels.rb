# frozen_string_literal: true

# This migration was skipped on production and will be replaced with a NOT VALID
# foreign key migration. See
# https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/work_items/28912
class AddMemberRoleFkToProtectedBranchUnprotectAccessLevels < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  def up
    # no-op
  end

  def down
    # no-op
  end
end
