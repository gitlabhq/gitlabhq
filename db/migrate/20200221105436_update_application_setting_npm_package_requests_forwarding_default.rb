# frozen_string_literal: true

class UpdateApplicationSettingNpmPackageRequestsForwardingDefault < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    change_column_default :application_settings, :npm_package_requests_forwarding, true

    execute('UPDATE application_settings SET npm_package_requests_forwarding = TRUE')
  end

  def down
    change_column_default :application_settings, :npm_package_requests_forwarding, false

    execute('UPDATE application_settings SET npm_package_requests_forwarding = FALSE')
  end
end
