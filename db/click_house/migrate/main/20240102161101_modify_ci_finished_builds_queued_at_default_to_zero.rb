# frozen_string_literal: true

class ModifyCiFinishedBuildsQueuedAtDefaultToZero < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds MODIFY COLUMN queued_at DEFAULT 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds MODIFY COLUMN queued_at DEFAULT now()
    SQL
  end
end
