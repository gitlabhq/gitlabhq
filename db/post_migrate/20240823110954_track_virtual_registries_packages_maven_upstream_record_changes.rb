# frozen_string_literal: true

class TrackVirtualRegistriesPackagesMavenUpstreamRecordChanges < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '17.4'

  def up
    track_record_deletions(:virtual_registries_packages_maven_upstreams)
  end

  def down
    untrack_record_deletions(:virtual_registries_packages_maven_upstreams)
  end
end
