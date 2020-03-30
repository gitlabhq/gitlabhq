# frozen_string_literal: true

class AddProjectsMaxArtifactsSize < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :projects, :max_artifacts_size, :integer # rubocop:disable Migration/AddColumnsToWideTables
  end
end
