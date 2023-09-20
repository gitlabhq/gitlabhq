# frozen_string_literal: true

class AddDecompressArchiveFileTimeoutToApplicationSetting < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def change
    add_column :application_settings, :decompress_archive_file_timeout, :integer, default: 210, null: false
  end
end
