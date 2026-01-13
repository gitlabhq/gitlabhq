# frozen_string_literal: true

class TrackVirtualRegistriesPackagesNpmUpstreamRecordChanges < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.8'

  def up
    track_record_deletions(:virtual_registries_packages_npm_upstreams)
  end

  def down
    untrack_record_deletions(:virtual_registries_packages_npm_upstreams)
  end
end
