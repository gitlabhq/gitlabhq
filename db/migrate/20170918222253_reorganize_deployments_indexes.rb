# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ReorganizeDeploymentsIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_index_if_not_exists :deployments, [:environment_id, :iid, :project_id]
    remove_index_if_exists :deployments, [:project_id, :environment_id, :iid]
  end

  def down
    add_index_if_not_exists :deployments, [:project_id, :environment_id, :iid]
    remove_index_if_exists :deployments, [:environment_id, :iid, :project_id]
  end

  def add_index_if_not_exists(table, columns)
    add_concurrent_index(table, columns) unless index_exists?(table, columns)
  end

  def remove_index_if_exists(table, columns)
    remove_concurrent_index(table, columns) if index_exists?(table, columns)
  end
end
