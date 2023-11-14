# frozen_string_literal: true

class AddAllowMergeWithoutPipelineToProjectSettings < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.6'

  def change
    add_column :project_settings, :allow_merge_without_pipeline, :boolean, default: false, null: false
  end
end
