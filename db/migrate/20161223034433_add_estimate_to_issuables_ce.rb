class AddEstimateToIssuablesCe < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    unless column_exists?(:issues, :time_estimate)
      add_column :issues, :time_estimate, :integer
    end

    unless column_exists?(:merge_requests, :time_estimate)
      add_column :merge_requests, :time_estimate, :integer
    end
  end
end
