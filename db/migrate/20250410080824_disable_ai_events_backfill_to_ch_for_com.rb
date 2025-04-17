# frozen_string_literal: true

class DisableAiEventsBackfillToChForCom < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.11'

  def up
    ::Feature.disable(:ai_events_backfill_to_ch) if Gitlab.org_or_com?
  end

  def down
    # no-op
  end
end
