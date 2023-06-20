# frozen_string_literal: true

class AddModelExperimentsAccessLevelToProjectFeature < Gitlab::Database::Migration[2.1]
  OPERATIONS_DEFAULT_VALUE = 20

  enable_lock_retries!

  def change
    add_column :project_features,
      :model_experiments_access_level,
      :integer,
      null: false,
      default: OPERATIONS_DEFAULT_VALUE
  end
end
