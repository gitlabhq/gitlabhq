# frozen_string_literal: true

class EnableHashedStorageByDefault < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    change_column_default :application_settings, :hashed_storage_enabled, true
  end

  def down
    change_column_default :application_settings, :hashed_storage_enabled, false
  end
end
