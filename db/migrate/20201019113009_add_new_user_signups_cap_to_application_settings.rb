# frozen_string_literal: true

class AddNewUserSignupsCapToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :new_user_signups_cap, :integer
  end
end
