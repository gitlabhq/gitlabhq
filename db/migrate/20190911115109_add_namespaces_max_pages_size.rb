# frozen_string_literal: true

class AddNamespacesMaxPagesSize < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :namespaces, :max_pages_size, :integer # rubocop:disable Migration/AddColumnsToWideTables
  end
end
