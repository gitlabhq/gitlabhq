# frozen_string_literal: true

class CleanupAllowLocalRequestsFromHooksAndServicesApplicationSettingRename < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    cleanup_concurrent_column_rename :application_settings, :allow_local_requests_from_hooks_and_services, :allow_local_requests_from_web_hooks_and_services
  end

  def down
    rename_column_concurrently :application_settings, :allow_local_requests_from_web_hooks_and_services, :allow_local_requests_from_hooks_and_services
  end
end
