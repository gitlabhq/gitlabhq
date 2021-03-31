# frozen_string_literal: true

class AddCloudToLicenses < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :licenses, :cloud, :boolean, default: false
  end
end
