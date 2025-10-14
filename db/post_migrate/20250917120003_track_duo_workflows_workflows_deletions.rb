# frozen_string_literal: true

class TrackDuoWorkflowsWorkflowsDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.5'

  def up
    track_record_deletions(:duo_workflows_workflows)
  end

  def down
    untrack_record_deletions(:duo_workflows_workflows)
  end
end
