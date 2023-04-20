# frozen_string_literal: true

class AddValidDeployAccessLevelConstraint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_deploy_access_levels_user_group_access_level_any_not_null'
  CONSTRAINT = '(num_nonnulls(user_id, group_id, access_level) = 1)'

  def up
    add_check_constraint :protected_environment_deploy_access_levels, CONSTRAINT, CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :protected_environment_deploy_access_levels, CONSTRAINT_NAME
  end
end
