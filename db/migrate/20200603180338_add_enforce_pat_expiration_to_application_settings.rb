# frozen_string_literal: true

class AddEnforcePatExpirationToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :enforce_pat_expiration, :boolean, default: true, null: false
  end
end
