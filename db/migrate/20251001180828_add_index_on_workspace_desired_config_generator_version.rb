# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexOnWorkspaceDesiredConfigGeneratorVersion < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :workspaces,
      :id,
      where: "desired_config_generator_version IS NULL",
      name: "idx_workspaces_null_config_version_id"
    )
  end

  def down
    remove_concurrent_index_by_name :workspaces, name: "idx_workspaces_null_config_version_id"
  end
end
