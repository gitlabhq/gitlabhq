# frozen_string_literal: true

class AddIncidentManagementThrottleColumnsToApplicationSetting < ActiveRecord::Migration[5.2]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    add_column(:application_settings,
                            :throttle_incident_management_notification_enabled,
                            :boolean,
                            null: false,
                            default: false)

    add_column(:application_settings,
                            :throttle_incident_management_notification_period_in_seconds,
                            :integer,
                            default: 3_600)

    add_column(:application_settings,
                            :throttle_incident_management_notification_per_period,
                            :integer,
                            default: 3_600)
  end

  def down
    remove_column :application_settings, :throttle_incident_management_notification_enabled
    remove_column :application_settings, :throttle_incident_management_notification_period_in_seconds
    remove_column :application_settings, :throttle_incident_management_notification_per_period
  end
end
