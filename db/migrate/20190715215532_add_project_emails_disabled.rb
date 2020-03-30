# frozen_string_literal: true

class AddProjectEmailsDisabled < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :projects, :emails_disabled, :boolean # rubocop:disable Migration/AddColumnsToWideTables
  end
end
