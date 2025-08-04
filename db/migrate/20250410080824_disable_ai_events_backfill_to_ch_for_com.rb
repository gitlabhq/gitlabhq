# frozen_string_literal: true

class DisableAiEventsBackfillToChForCom < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.11'

  def up
    # no-op
  end

  def down
    # no-op
  end
end
