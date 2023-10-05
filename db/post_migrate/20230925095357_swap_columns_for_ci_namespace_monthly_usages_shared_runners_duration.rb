# frozen_string_literal: true

class SwapColumnsForCiNamespaceMonthlyUsagesSharedRunnersDuration < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :ci_namespace_monthly_usages
  OLD_COLUMN_NAME = :shared_runners_duration
  NEW_COLUMN_NAME = :shared_runners_duration_convert_to_bigint
  TEMP_COLUMN_NAME = :temp_shared_runners_duration

  def up
    swap
  end

  def down
    swap
  end

  private

  def swap
    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{OLD_COLUMN_NAME} TO #{TEMP_COLUMN_NAME}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{NEW_COLUMN_NAME} TO #{OLD_COLUMN_NAME}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{TEMP_COLUMN_NAME} TO #{NEW_COLUMN_NAME}"
    end
  end
end
