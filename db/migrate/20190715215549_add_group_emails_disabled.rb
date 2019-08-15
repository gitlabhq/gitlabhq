# frozen_string_literal: true

class AddGroupEmailsDisabled < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :namespaces, :emails_disabled, :boolean
  end
end
