# frozen_string_literal: true

class AddMergeTrainEnforcementToProjectCiCdSettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :project_ci_cd_settings, :merge_train_enforcement, :smallint, default: 0, null: false
  end
end
