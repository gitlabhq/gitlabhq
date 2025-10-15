# frozen_string_literal: true

class RemoveWorkspaceDesiredConfigGeneratorVersionColumn < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    remove_column :workspaces, :desired_config_generator_version, if_exists: true
  end

  def down
    add_column :workspaces, :desired_config_generator_version, :integer, default: 3, if_not_exists: true
    add_concurrent_index(
      :workspaces,
      :id,
      where: "desired_config_generator_version IS NULL",
      name: "idx_workspaces_null_config_version_id"
    )
  end
end
