# frozen_string_literal: true

class ChangeOutboundLocalRequestsWhitelistDefault < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  def up
    default_value = []

    change_column_default(:application_settings, :outbound_local_requests_whitelist, default_value)

    ApplicationSetting
      .where(outbound_local_requests_whitelist: nil)
      .update(outbound_local_requests_whitelist: default_value)

    change_column_null(:application_settings, :outbound_local_requests_whitelist, false)
  end

  def down
    change_column_null(:application_settings, :outbound_local_requests_whitelist, true)

    change_column_default(:application_settings, :outbound_local_requests_whitelist, nil)
  end
end
