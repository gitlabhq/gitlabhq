# frozen_string_literal: true

class RemoveStorageSizeLimitFromApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    remove_column :application_settings, :namespace_storage_size_limit
  end

  def down
    add_column :application_settings, :namespace_storage_size_limit, :bigint, default: 0
  end
end
