# rubocop:disable all
class AddClientsideSentryToApplicationSettings < ActiveRecord::Migration
  DOWNTIME = true
  DOWNTIME_REASON = 'This migration requires downtime because we must add 2 new columns, 1 of which has a default value.'

  def change
    change_table :application_settings do |t|
      t.boolean :clientside_sentry_enabled, default: false
      t.string :clientside_sentry_dsn
    end
  end
end
