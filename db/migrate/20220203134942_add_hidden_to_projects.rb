# frozen_string_literal: true

class AddHiddenToProjects < Gitlab::Database::Migration[1.0]
  DOWNTIME = false

  enable_lock_retries!

  def change
    add_column :projects, :hidden, :boolean, default: false, null: false # rubocop: disable Migration/AddColumnsToWideTables
  end
end
