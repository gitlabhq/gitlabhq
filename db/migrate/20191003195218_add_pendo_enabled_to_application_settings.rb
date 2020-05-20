class AddPendoEnabledToApplicationSettings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings, :pendo_enabled, :boolean, default: false, allow_null: false # rubocop:disable Migration/AddColumnWithDefault
  end

  def down
    remove_column :application_settings, :pendo_enabled
  end
end
