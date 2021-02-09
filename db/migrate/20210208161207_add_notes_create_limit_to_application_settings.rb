# frozen_string_literal: true

class AddNotesCreateLimitToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :notes_create_limit, :integer, default: 300, null: false
  end
end
