# frozen_string_literal: true

class AddRequirementsAccessLevelToProjectFeatures < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :project_features, :requirements_access_level, :integer, default: 20, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :project_features, :requirements_access_level, :integer
    end
  end
end
