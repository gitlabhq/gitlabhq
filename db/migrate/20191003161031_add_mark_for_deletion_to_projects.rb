# frozen_string_literal: true

class AddMarkForDeletionToProjects < ActiveRecord::Migration[5.2]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # rubocop:disable Migration/AddColumnsToWideTables
  def change
    add_column :projects, :marked_for_deletion_at, :date
    add_column :projects, :marked_for_deletion_by_user_id, :integer
  end
  # rubocop:enable Migration/AddColumnsToWideTables
end
