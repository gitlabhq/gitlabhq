# frozen_string_literal: true

class AddMrMetricsFirstApprovedAt < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :merge_request_metrics, :first_approved_at, :datetime_with_timezone
  end

  def down
    remove_column :merge_request_metrics, :first_approved_at
  end
end
