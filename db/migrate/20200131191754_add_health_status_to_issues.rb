# frozen_string_literal: true

class AddHealthStatusToIssues < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :issues, :health_status, :integer, limit: 2
  end
end
