# frozen_string_literal: true

class AddStatusToPackagesPackages < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :packages_packages, :status, :smallint, default: 0, null: false
  end
end
