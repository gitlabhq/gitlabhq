# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropNotNullConstraintDesiredConfigGeneratorVersionColumnWorkspaceTable < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    remove_check_constraint :workspaces, 'check_35e31ca320'
  end

  def down
    add_check_constraint :workspaces, 'desired_config_generator_version IS NOT NULL', 'check_35e31ca320'
  end
end
