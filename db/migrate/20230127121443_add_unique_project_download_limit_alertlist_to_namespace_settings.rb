# frozen_string_literal: true

class AddUniqueProjectDownloadLimitAlertlistToNamespaceSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :namespace_settings, :unique_project_download_limit_alertlist,
      :integer,
      array: true,
      default: [],
      null: false
  end
end
