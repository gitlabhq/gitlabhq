# frozen_string_literal: true

class AddMaxPersonalAccessTokenLifetimeToApplicationSettings < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :application_settings, :max_personal_access_token_lifetime, :integer
  end
end
