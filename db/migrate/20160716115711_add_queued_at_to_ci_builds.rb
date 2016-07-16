class AddQueuedAtToCiBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :ci_builds, :queued_at, :timestamp
  end
end
