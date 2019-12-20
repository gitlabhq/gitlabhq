# frozen_string_literal: true

class AddMentionsDisabledToNamespaces < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :namespaces, :mentions_disabled, :boolean
  end
end
