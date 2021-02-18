# frozen_string_literal: true

class AddKrokiFormatsToApplicationSettingsTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_table :application_settings do |t|
      t.jsonb :kroki_formats, null: false, default: {}
    end
  end
end
