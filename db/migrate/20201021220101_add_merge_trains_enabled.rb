# frozen_string_literal: true

class AddMergeTrainsEnabled < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :project_ci_cd_settings, :merge_trains_enabled, :boolean, default: false, allow_null: false
  end
end
