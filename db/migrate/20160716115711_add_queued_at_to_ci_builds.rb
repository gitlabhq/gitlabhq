# rubocop:disable Migration/Datetime
class AddQueuedAtToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_builds, :queued_at, :timestamp
  end
end
