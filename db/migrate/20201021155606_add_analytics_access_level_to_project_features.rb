# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddAnalyticsAccessLevelToProjectFeatures < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :project_features, :analytics_access_level, :integer, default: 20, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :project_features, :analytics_access_level, :integer
    end
  end
end
