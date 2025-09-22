# frozen_string_literal: true

class TrackPackagesPackageFileDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.5'

  def up
    track_record_deletions(:packages_package_files)
  end

  def down
    untrack_record_deletions(:packages_package_files)
  end
end
