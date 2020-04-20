# frozen_string_literal: true

class ValidateProtectedBranchPushAccessLevelsUserIdForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  CONSTRAINT_NAME = 'fk_protected_branch_push_access_levels_user_id'

  def up
    validate_foreign_key :protected_branch_push_access_levels, :user_id, name: CONSTRAINT_NAME
  end

  def down
    # no op
  end
end
