# frozen_string_literal: true

class AddGitlabInstanceAdministrationProject < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    BackgroundMigrationWorker.perform_async('AddGitlabInstanceAdministrationProject', [])
  end

  def down
    ApplicationSetting.current_without_cache
      &.instance_administration_project
      &.owner
      &.destroy!
  end
end
