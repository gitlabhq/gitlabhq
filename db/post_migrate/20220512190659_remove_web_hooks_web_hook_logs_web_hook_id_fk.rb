# frozen_string_literal: true

class RemoveWebHooksWebHookLogsWebHookIdFk < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  PARENT_TABLE_NAME = :web_hook_logs
  FK_NAME = "fk_rails_bb3355782d"

  def up
    with_lock_retries do
      execute('LOCK web_hooks, web_hook_logs IN ACCESS EXCLUSIVE MODE') if transaction_open?

      remove_foreign_key_if_exists(:web_hook_logs, :web_hooks, name: FK_NAME)
    end
  end

  def down
    fk_attrs = {
      name: FK_NAME, # Note we need the same name for every partition
      column: :web_hook_id,
      target_column: :id,
      on_delete: :cascade
    }

    # Must add child FK's first, then to the partitioned table.
    child_tables.each do |tbl|
      add_concurrent_foreign_key(
        tbl, :web_hooks,
        # This embeds the lock table statement in the with_lock_retries inside add_concurrent_foreign_key
        reverse_lock_order: true,
        **fk_attrs)
    end

    with_lock_retries do
      execute("LOCK web_hooks, #{PARENT_TABLE_NAME} IN ACCESS EXCLUSIVE MODE") if transaction_open?
      add_foreign_key(:web_hook_logs, :web_hooks, **fk_attrs)
    end
  end

  # This table is partitioned: we need to apply the index changes to each
  # partition separately.
  def child_tables
    @child_tables ||= execute(<<~SQL.squish).pluck("child")
      SELECT inhrelid::regclass AS child
      FROM   pg_catalog.pg_inherits
      WHERE  inhparent = '#{PARENT_TABLE_NAME}'::regclass
      ORDER BY inhrelid ASC
    SQL
  end
end
