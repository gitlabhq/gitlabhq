# frozen_string_literal: true

class AddNamespaceSettingsUniqueProjectDownloadLimitAllowlistSizeConstraint < Gitlab::Database::Migration[2.0]
  CONSTRAINT_NAME = 'namespace_settings_unique_project_download_limit_allowlist_size'

  disable_ddl_transaction!

  def up
    add_check_constraint :namespace_settings,
      'CARDINALITY(unique_project_download_limit_allowlist) <= 100',
      CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :namespace_settings, CONSTRAINT_NAME
  end
end
