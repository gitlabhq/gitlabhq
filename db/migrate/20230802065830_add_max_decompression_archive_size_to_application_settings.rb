# frozen_string_literal: true

class AddMaxDecompressionArchiveSizeToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :max_decompressed_archive_size, :integer, default: 25600, null: false
  end
end
