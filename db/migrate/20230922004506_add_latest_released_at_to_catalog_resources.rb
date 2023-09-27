# frozen_string_literal: true

class AddLatestReleasedAtToCatalogResources < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :catalog_resources, :latest_released_at, :datetime_with_timezone, null: true
  end
end
