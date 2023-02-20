# frozen_string_literal: true

class AddNamespaceSettingsUniqueProjectDownloadLimitAlertlistSizeConstraint < Gitlab::Database::Migration[2.1]
  CONSTRAINT_NAME = 'namespace_settings_unique_project_download_limit_alertlist_size'

  disable_ddl_transaction!

  def up
    add_check_constraint :namespace_settings,
      'CARDINALITY(unique_project_download_limit_alertlist) <= 100',
      CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :namespace_settings, CONSTRAINT_NAME
  end
end
