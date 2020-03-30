# frozen_string_literal: true

class AddProcessedToCiBuilds < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :ci_builds, :processed, :boolean # rubocop:disable Migration/AddColumnsToWideTables
  end
end
