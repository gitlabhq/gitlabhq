# frozen_string_literal: true

class AddStatusToErrorTrackingError < ActiveRecord::Migration[6.1]
  def up
    add_column :error_tracking_errors, :status, :integer, null: false, default: 0, limit: 2
  end

  def down
    remove_column :error_tracking_errors, :status
  end
end
