# frozen_string_literal: true

class StealBackgroundJobsThatReferenceServices < ActiveRecord::Migration[6.1]
  def up
    Gitlab::BackgroundMigration.steal('BackfillJiraTrackerDeploymentType2')
    Gitlab::BackgroundMigration.steal('FixProjectsWithoutPrometheusService')
    Gitlab::BackgroundMigration.steal('MigrateIssueTrackersSensitiveData')
    Gitlab::BackgroundMigration.steal('RemoveDuplicateServices')
  end

  def down
    # no-op
  end
end
