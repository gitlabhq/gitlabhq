# frozen_string_literal: true

class AddClosedByFieldsToResourceStateEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :resource_state_events, :close_after_error_tracking_resolve, :boolean, default: false, null: false
    add_column :resource_state_events, :close_auto_resolve_prometheus_alert, :boolean, default: false, null: false
  end

  def down
    remove_column :resource_state_events, :close_auto_resolve_prometheus_alert, :boolean
    remove_column :resource_state_events, :close_after_error_tracking_resolve, :boolean
  end
end
