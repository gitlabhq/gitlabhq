class AddEstimateToIssuables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    unless column_exists?(:issues, :time_estimate)
      add_column :issues, :time_estimate, :integer
    end

    unless column_exists?(:merge_requests, :time_estimate)
      add_column :merge_requests, :time_estimate, :integer
    end
  end

  def down
    if column_exists?(:issues, :time_estimate)
      remove_column :issues, :time_estimate
    end

    if column_exists?(:merge_requests, :time_estimate)
      remove_column :merge_requests, :time_estimate
    end
  end
end
