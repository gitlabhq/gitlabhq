# frozen_string_literal: true

class AddSetupForCompanyToUserPreferences < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :user_preferences, :setup_for_company, :boolean
  end
end
