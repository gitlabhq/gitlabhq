# frozen_string_literal: true

class AddExecutionConfigIdToPCiBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  # rubocop:disable Migration/AddColumnsToWideTables -- We need this to store run step config
  def up
    add_column :p_ci_builds, :execution_config_id, :bigint # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
  end
  # rubocop:enable Migration/AddColumnsToWideTables

  def down
    remove_column :p_ci_builds, :execution_config_id
  end
end
