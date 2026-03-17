# frozen_string_literal: true

class AddBlobDownloadTimeoutToGeoNodes < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :geo_nodes, :blob_download_timeout, :integer, default: 28800, null: false, if_not_exists: true
  end
end
