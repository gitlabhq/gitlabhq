# frozen_string_literal: true

class TrackAiActiveContextConnectionsDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.2'

  def up
    track_record_deletions(:ai_active_context_connections)
  end

  def down
    untrack_record_deletions(:ai_active_context_connections)
  end
end
