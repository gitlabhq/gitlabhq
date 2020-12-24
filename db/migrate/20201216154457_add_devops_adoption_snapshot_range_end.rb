# frozen_string_literal: true

class AddDevopsAdoptionSnapshotRangeEnd < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :analytics_devops_adoption_snapshots, :end_time, :datetime_with_timezone
  end
end
