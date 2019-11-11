# frozen_string_literal: true

class AddLicenseDetailsToApplicationSettings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :license_trial_ends_on, :date, null: true
  end
end
