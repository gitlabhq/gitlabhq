# frozen_string_literal: true

class AddLastDownloadedAtToPackages < Gitlab::Database::Migration[2.0]
  def change
    add_column :packages_packages, :last_downloaded_at, :datetime_with_timezone
  end
end
