# frozen_string_literal: true

class AddVerifyKnownSignInToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :notify_on_unknown_sign_in, :boolean, default: true, null: false
  end
end
