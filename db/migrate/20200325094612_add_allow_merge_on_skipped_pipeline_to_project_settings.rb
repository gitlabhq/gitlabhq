# frozen_string_literal: true

class AddAllowMergeOnSkippedPipelineToProjectSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :project_settings, :allow_merge_on_skipped_pipeline, :boolean
  end
end
