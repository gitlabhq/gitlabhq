# frozen_string_literal: true

class RequeueBackfillStateTransitionOccurrenceId < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  def up
    # Re-queued back again in db/post_migrate/20260402065629_requeue_backfill_state_transition_occurrence_id.rb
    # no-op
  end

  def down
    # Re-queued back again in db/post_migrate/20260402065629_requeue_backfill_state_transition_occurrence_id.rb
    # no-op
  end
end
