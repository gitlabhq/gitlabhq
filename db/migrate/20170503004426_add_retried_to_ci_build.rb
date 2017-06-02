class AddRetriedToCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column(:ci_builds, :retried, :boolean)
  end
end
