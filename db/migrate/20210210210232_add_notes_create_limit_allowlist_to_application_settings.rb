# frozen_string_literal: true

class AddNotesCreateLimitAllowlistToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :notes_create_limit_allowlist, :text, array: true, default: [], null: false
  end
end
