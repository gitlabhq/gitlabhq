# frozen_string_literal: true

class AddStatusToPackagesNpmMetadataCaches < Gitlab::Database::Migration[2.1]
  def change
    add_column :packages_npm_metadata_caches, :status, :integer, default: 0, null: false, limit: 2
  end
end
