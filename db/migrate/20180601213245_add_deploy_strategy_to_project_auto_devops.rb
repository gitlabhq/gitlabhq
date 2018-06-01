# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDeployStrategyToProjectAutoDevops < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    change_table :project_auto_devops do |t|
      t.integer :deploy_strategy, null: false, default: 0
    end
  end
end
