# frozen_string_literal: true

class DropWorkspacesDesiredConfigGeneratorVersionDefault < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    change_column_default :workspaces, :desired_config_generator_version, from: 1, to: nil
  end
end
