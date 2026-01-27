# frozen_string_literal: true

class AddStateColumnInCiRunnerControllers < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    # Add state column: 0=disabled, 1=enabled, 2=dry_run
    add_column :ci_runner_controllers, :state, :integer, limit: 2, default: 0, null: false
  end

  def down
    remove_column :ci_runner_controllers, :state
  end
end
