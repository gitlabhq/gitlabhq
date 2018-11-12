# frozen_string_literal: true

class DropDefaultValueOnStatusDeployments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  DEPLOYMENT_STATUS_SUCCESS = 2 # Equivalent to Deployment.state_machine.states['success'].value

  disable_ddl_transaction!

  def up
    change_column_default :deployments, :status, :nil
  end

  def down
    change_column_default :deployments, :status, DEPLOYMENT_STATUS_SUCCESS
  end
end
