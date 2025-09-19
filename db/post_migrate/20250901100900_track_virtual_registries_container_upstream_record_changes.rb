# frozen_string_literal: true

class TrackVirtualRegistriesContainerUpstreamRecordChanges < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.5'

  def up
    track_record_deletions(:virtual_registries_container_upstreams)
  end

  def down
    untrack_record_deletions(:virtual_registries_container_upstreams)
  end
end
