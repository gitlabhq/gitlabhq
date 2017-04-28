# rubocop:disable all
class AddClientsideSentryToApplicationSettings < ActiveRecord::Migration
  def change
    change_table :application_settings do |t|
      t.boolean :clientside_sentry_enabled, default: false
      t.string :clientside_sentry_dsn
    end
  end
end
