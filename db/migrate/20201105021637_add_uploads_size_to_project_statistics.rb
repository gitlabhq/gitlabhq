# frozen_string_literal: true

class AddUploadsSizeToProjectStatistics < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :project_statistics, :uploads_size, :bigint, default: 0, null: false
  end

  def down
    remove_column :project_statistics, :uploads_size
  end
end
