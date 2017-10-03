# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDeploymentsIndexForLastDeployment < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  TO_INDEX = [:deployments, %i[environment_id id]].freeze

  def up
    add_concurrent_index(*TO_INDEX)
  end

  def down
    remove_concurrent_index(*TO_INDEX)
  end
end
