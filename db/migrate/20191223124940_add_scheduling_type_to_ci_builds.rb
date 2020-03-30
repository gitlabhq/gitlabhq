# frozen_string_literal: true

class AddSchedulingTypeToCiBuilds < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_builds, :scheduling_type, :integer, limit: 2 # rubocop:disable Migration/AddColumnsToWideTables
  end
end
