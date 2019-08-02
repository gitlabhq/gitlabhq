# frozen_string_literal: true

class AddAllowLocalRequestsFromSystemHooksToApplicationSettings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column(:application_settings, :allow_local_requests_from_system_hooks,
               :boolean,
               default: true,
               null: false)
  end

  def down
    remove_column(:application_settings, :allow_local_requests_from_system_hooks)
  end
end
