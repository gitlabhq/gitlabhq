# frozen_string_literal: true

class AddActionToDeployments < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DEPLOYMENT_ACTION_START = 1 # Equivalent to Deployment.actions['start']

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:deployments,
      :action,
      :integer,
      limit: 2,
      default: DEPLOYMENT_ACTION_START,
      allow_null: false)
  end

  def down
    remove_column(:deployments, :action)
  end
end
