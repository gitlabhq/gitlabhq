# frozen_string_literal: true

class AddExecutionConfigIdToPCiBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    # rubocop:disable Migration/PreventAddingColumns -- We need this to store run step config
    add_column :p_ci_builds, :execution_config_id, :bigint
    # rubocop:enable Migration/PreventAddingColumns
  end

  def down
    remove_column :p_ci_builds, :execution_config_id
  end
end
