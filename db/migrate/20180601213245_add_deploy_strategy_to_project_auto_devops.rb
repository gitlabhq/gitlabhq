# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDeployStrategyToProjectAutoDevops < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :project_auto_devops, :deploy_strategy, :integer, default: 0, allow_null: false # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :project_auto_devops, :deploy_strategy
  end
end
