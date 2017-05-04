class AddRetriedToCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:ci_builds, :retried, :boolean, default: false)
  end

  def down
    remove_column(:ci_builds, :retried)
  end
end
