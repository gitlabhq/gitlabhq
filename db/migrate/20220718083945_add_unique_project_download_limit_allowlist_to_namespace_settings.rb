# frozen_string_literal: true

class AddUniqueProjectDownloadLimitAllowlistToNamespaceSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :namespace_settings, :unique_project_download_limit_allowlist,
      :text,
      array: true,
      default: [],
      null: false
  end
end
