# frozen_string_literal: true

class AddMergePipelinesEnabledToCiCdSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :project_ci_cd_settings, :merge_pipelines_enabled, :boolean
  end
end
