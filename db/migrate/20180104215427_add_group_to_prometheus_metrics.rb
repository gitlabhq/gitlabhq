# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddGroupToPrometheusMetrics < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  def change
    add_column :prometheus_metrics, :group, :integer
    add_index :prometheus_metrics, :group
  end
end
