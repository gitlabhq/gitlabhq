class AddProjectExportEnabledToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    remove_column(:ci_trigger_requests, :variables)
  end

  def down
    add_column(:ci_trigger_requests, :variables, :text)
  end
end
