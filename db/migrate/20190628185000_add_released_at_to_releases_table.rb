# frozen_string_literal: true

class AddReleasedAtToReleasesTable < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column(:releases, :released_at, :datetime_with_timezone)
  end
end
