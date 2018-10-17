# frozen_string_literal: true

class AddStatusToDeployments < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :deployments, :status, :integer, limit: 2
    add_column :deployments, :finished_at, :datetime_with_timezone
  end
end
