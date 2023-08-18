# frozen_string_literal: true

class AddMaxFileDownloadSizeToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :bulk_import_max_download_file_size, :bigint, default: 5120, null: false
  end
end
