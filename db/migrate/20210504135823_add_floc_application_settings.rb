# frozen_string_literal: true

class AddFlocApplicationSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :application_settings, :floc_enabled, :boolean, default: false, null: false
  end
end
