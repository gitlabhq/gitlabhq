# frozen_string_literal: true

class AddStatusToDeployments < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DEPLOYMENT_STATUS_SUCCESS = 2 # Equivalent to Deployment.state_machine.states['success'].value

  DOWNTIME = false

  disable_ddl_transaction!

  ##
  # NOTE:
  # Ideally, `status` column should not have default value because it should be leveraged by state machine (i.e. application level).
  # However, we have to use the default value for avoiding `NOT NULL` violation during the transition period.
  # The default value should be removed in the future release.
  def up
    add_column_with_default(:deployments, # rubocop:disable Migration/AddColumnWithDefault
      :status,
      :integer,
      limit: 2,
      default: DEPLOYMENT_STATUS_SUCCESS,
      allow_null: false)
  end

  def down
    remove_column(:deployments, :status)
  end
end
