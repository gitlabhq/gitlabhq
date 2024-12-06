# frozen_string_literal: true

class TrackAiConversationThredRecordChanges < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '17.7'

  def up
    track_record_deletions(:ai_conversation_threads)
  end

  def down
    untrack_record_deletions(:ai_conversation_threads)
  end
end
