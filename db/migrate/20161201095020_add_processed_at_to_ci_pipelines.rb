class AddProcessedAtToCiPipelines < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column(:ci_commits, :processed_at, :datetime)
  end
end
