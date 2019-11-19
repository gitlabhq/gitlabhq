# frozen_string_literal: true

class RemovePendoFromApplicationSettings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    remove_column :application_settings, :pendo_enabled
    remove_column :application_settings, :pendo_url
  end

  def down
    add_column_with_default :application_settings, :pendo_enabled, :boolean, default: false, allow_null: false
    add_column :application_settings, :pendo_url, :string, limit: 255
  end
end
