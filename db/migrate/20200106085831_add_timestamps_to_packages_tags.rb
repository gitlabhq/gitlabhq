# frozen_string_literal: true

class AddTimestampsToPackagesTags < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # We disable these cops here because adding this column is safe. The table does not
  # have any data in it.
  # rubocop: disable Migration/AddIndex
  def up
    add_timestamps_with_timezone(:packages_tags, null: false)
    add_index(:packages_tags, [:package_id, :updated_at], order: { updated_at: :desc })
  end

  # We disable these cops here because adding this column is safe. The table does not
  # have any data in it.
  # rubocop: disable Migration/RemoveIndex
  def down
    remove_index(:packages_tags, [:package_id, :updated_at])
    remove_timestamps(:packages_tags)
  end
end
