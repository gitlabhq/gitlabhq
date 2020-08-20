# frozen_string_literal: true

class AddPreventForkingToNamespaceSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :namespace_settings, :prevent_forking_outside_group, :boolean, null: false, default: false
  end
end
