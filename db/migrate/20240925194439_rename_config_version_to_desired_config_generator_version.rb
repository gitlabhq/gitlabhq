# frozen_string_literal: true

class RenameConfigVersionToDesiredConfigGeneratorVersion < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  def up
    rename_column_concurrently :workspaces, :config_version, :desired_config_generator_version
  end

  def down
    undo_rename_column_concurrently :workspaces, :config_version, :desired_config_generator_version
  end
end
