# frozen_string_literal: true

class ModifyCiFinishedBuildsStartedAtDefaultToZero < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds MODIFY COLUMN started_at DEFAULT 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds MODIFY COLUMN started_at DEFAULT COALESCE(finished_at, 0)
    SQL
  end
end
