# frozen_string_literal: true

class RemoveImportedColumnOnResourceMilestoneEvents < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    remove_column :resource_milestone_events, :imported
  end

  def down
    add_column :resource_milestone_events, :imported, :integer, default: 0, null: false, limit: 2
  end
end
