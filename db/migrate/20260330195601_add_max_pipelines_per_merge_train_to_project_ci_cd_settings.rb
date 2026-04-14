# frozen_string_literal: true

class AddMaxPipelinesPerMergeTrainToProjectCiCdSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :project_ci_cd_settings, :max_pipelines_per_merge_train, :smallint, default: nil
  end
end
