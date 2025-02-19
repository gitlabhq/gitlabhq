# frozen_string_literal: true

class RemoveWorkspaceMaxHoursBeforeTerminationColumn < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    remove_column :workspaces, :max_hours_before_termination
  end

  def down
    add_column(:workspaces, :max_hours_before_termination, :smallint, null: false, default: 8760, if_not_exists: true)
  end
end
