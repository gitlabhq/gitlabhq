# frozen_string_literal: true

class RenameConfigVersionToDesiredConfigGeneratorVersion < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  def up
    # We need this additional step for adding the config_version column as a safeguard before the rename
    # Due to reported incidents where the config_version field did not exist in the database in some cases
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165876#note_2143316494 for more details
    add_column :workspaces, :config_version, :integer, default: 1, null: false, if_not_exists: true
    rename_column_concurrently :workspaces, :config_version, :desired_config_generator_version
  end

  def down
    undo_rename_column_concurrently :workspaces, :config_version, :desired_config_generator_version
  end
end
