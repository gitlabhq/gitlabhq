# frozen_string_literal: true

class TrackClusterAgentRecordChanges < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '17.5'

  def up
    track_record_deletions(:cluster_agents)
  end

  def down
    untrack_record_deletions(:cluster_agents)
  end
end
