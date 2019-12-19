# frozen_string_literal: true

class AddDeploymentEventsToServices < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:services, :deployment_events, :boolean, default: false, allow_null: false) # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column(:services, :deployment_events)
  end
end
