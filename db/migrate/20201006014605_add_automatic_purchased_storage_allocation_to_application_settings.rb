# frozen_string_literal: true

class AddAutomaticPurchasedStorageAllocationToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :automatic_purchased_storage_allocation, :boolean, default: false, null: false
  end
end
