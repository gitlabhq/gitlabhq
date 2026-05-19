# frozen_string_literal: true

class TrackPackagesDebianProjectComponentFileRecordChanges < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '19.0'

  def up
    track_record_deletions(:packages_debian_project_component_files)
  end

  def down
    untrack_record_deletions(:packages_debian_project_component_files)
  end
end
