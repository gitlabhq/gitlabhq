# frozen_string_literal: true

class AddIsDefaultBranchToCiFinishedPipelines < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_pipelines ADD COLUMN IF NOT EXISTS is_default_branch Bool DEFAULT false
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_pipelines DROP COLUMN IF EXISTS is_default_branch
    SQL
  end
end
