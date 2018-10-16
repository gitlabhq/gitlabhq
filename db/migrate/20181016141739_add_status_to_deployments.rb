# frozen_string_literal: true

class AddStatusToDeployments < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :deployments, :status, :integer, limit: 2
  end
end
