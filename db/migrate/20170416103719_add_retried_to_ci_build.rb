class AddRetriedToCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column(:ci_builds, :retried, :boolean)
  end

  def down
    remove_column(:ci_builds, :retried)
  end
end
