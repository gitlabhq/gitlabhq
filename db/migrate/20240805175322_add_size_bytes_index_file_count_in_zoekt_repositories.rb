# frozen_string_literal: true

class AddSizeBytesIndexFileCountInZoektRepositories < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    add_column :zoekt_repositories, :size_bytes, :bigint, default: 0, null: false
    add_column :zoekt_repositories, :index_file_count, :int, default: 0, null: false
  end
end
