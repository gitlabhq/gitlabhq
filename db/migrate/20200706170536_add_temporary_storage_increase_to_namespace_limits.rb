# frozen_string_literal: true

class AddTemporaryStorageIncreaseToNamespaceLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :namespace_limits, :temporary_storage_increase_ends_on, :date, null: true
  end
end
