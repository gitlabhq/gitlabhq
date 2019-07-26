# frozen_string_literal: true

class AddAllowLocalRequestsFromSystemHooksToApplicationSettings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :allow_local_requests_from_system_hooks,
                            :boolean,
                            default: true,
                            allow_null: false)
  end

  def down
    remove_column(:application_settings, :allow_local_requests_from_system_hooks)
  end
end
