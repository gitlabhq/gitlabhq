# frozen_string_literal: true

class ModifyCiFinishedBuildsFinishedAtDefault < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds MODIFY COLUMN finished_at DEFAULT 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds MODIFY COLUMN finished_at DEFAULT now()
    SQL
  end
end
