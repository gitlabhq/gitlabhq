# frozen_string_literal: true

class AddAutoDevOpsEnabledToNamespaces < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :namespaces, :auto_devops_enabled, :boolean
  end
end
