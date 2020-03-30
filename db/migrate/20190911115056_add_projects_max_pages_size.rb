# frozen_string_literal: true

class AddProjectsMaxPagesSize < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :projects, :max_pages_size, :integer # rubocop:disable Migration/AddColumnsToWideTables
  end
end
