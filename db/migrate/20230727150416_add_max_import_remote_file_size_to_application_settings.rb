# frozen_string_literal: true

class AddMaxImportRemoteFileSizeToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :max_import_remote_file_size, :bigint, default: 10240, null: false
  end
end
