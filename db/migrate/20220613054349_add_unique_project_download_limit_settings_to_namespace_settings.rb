# frozen_string_literal: true

class AddUniqueProjectDownloadLimitSettingsToNamespaceSettings < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :namespace_settings, :unique_project_download_limit, :smallint,
      default: 0, null: false
    add_column :namespace_settings, :unique_project_download_limit_interval_in_seconds, :integer,
      default: 0, null: false
  end
end
