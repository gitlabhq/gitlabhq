class AddAllowLocalRequestsFromHooksAndServicesToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :allow_local_requests_from_hooks_and_services,
                            :boolean,
                            default: false,
                            allow_null: false)
  end

  def down
    remove_column(:application_settings, :allow_local_requests_from_hooks_and_services)
  end
end
