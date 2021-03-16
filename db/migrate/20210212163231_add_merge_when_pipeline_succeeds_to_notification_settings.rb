# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddMergeWhenPipelineSucceedsToNotificationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :notification_settings, :merge_when_pipeline_succeeds, :boolean, default: false, null: false
  end
end
