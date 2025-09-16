# frozen_string_literal: true

class TrackPackagesNugetSymbolRecordChanges < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.4'

  def up
    track_record_deletions(:packages_nuget_symbols)
  end

  def down
    untrack_record_deletions(:packages_nuget_symbols)
  end
end
