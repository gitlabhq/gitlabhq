class AddSentryToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    change_table :application_settings do |t|
      t.boolean :sentry_enabled, default: false
      t.string :sentry_dsn
    end
  end
end
