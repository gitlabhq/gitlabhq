# frozen_string_literal: true

class AddRequirementsAccessLevelToProjectFeatures < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    unless column_exists?(:project_features, :requirements_access_level)
      with_lock_retries { add_column :project_features, :requirements_access_level, :integer, default: 20, null: false }
    end
  end

  def down
    if column_exists?(:project_features, :requirements_access_level)
      with_lock_retries { remove_column :project_features, :requirements_access_level }
    end
  end
end
