# frozen_string_literal: true

class AddDefaultValueToWorkspaceDesiredConfigGeneratorVersion < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    change_column_default :workspaces, :desired_config_generator_version, 3
  end

  def down
    change_column_default :workspaces, :desired_config_generator_version, nil
  end
end
