# frozen_string_literal: true

class RemoveFkWebHookLogsDailyProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    # no-op: replaced by 20260312101019_retry_remove_fk_web_hook_logs_daily_project_id
  end

  def down
    # no-op
  end
end
