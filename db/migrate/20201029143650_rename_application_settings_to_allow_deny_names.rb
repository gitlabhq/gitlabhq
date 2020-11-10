# frozen_string_literal: true

class RenameApplicationSettingsToAllowDenyNames < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently :application_settings, :domain_blacklist_enabled, :domain_denylist_enabled
    rename_column_concurrently :application_settings, :domain_blacklist, :domain_denylist
    rename_column_concurrently :application_settings, :domain_whitelist, :domain_allowlist
  end

  def down
    undo_rename_column_concurrently :application_settings, :domain_blacklist_enabled, :domain_denylist_enabled
    undo_rename_column_concurrently :application_settings, :domain_blacklist, :domain_denylist
    undo_rename_column_concurrently :application_settings, :domain_whitelist, :domain_allowlist
  end
end
