# frozen_string_literal: true

class ModifyCiFinishedBuildsSettings < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE ci_finished_builds MODIFY SETTING use_async_block_ids_cache = true
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ci_finished_builds MODIFY SETTING use_async_block_ids_cache = false
    SQL
  end
end
