# frozen_string_literal: true

class AddIssuesCreateLimitToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :issues_create_limit, :integer, default: 300, null: false
  end
end
