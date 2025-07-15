# frozen_string_literal: true

class TrackAiActiveContextEnabledNamespaceDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.2'

  def up
    track_record_deletions(:p_ai_active_context_code_enabled_namespaces)
  end

  def down
    untrack_record_deletions(:p_ai_active_context_code_enabled_namespaces)
  end
end
