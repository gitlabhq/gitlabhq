# frozen_string_literal: true

class AddGitlabInstanceAdministrationProject < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService.new.execute!
  end

  def down
    ApplicationSetting.current_without_cache
      &.instance_administration_project
      &.owner
      &.destroy!
  end
end
