# frozen_string_literal: true

class ModifyCiFinishedBuildsCreatedAtDefaultToZero < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds MODIFY COLUMN created_at DEFAULT 0
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds MODIFY COLUMN created_at DEFAULT now()
    SQL
  end
end
