# frozen_string_literal: true

class AddReleasePublishedAtToRelease < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  enable_lock_retries!

  def change
    add_column :releases, :release_published_at, :datetime_with_timezone
  end
end
