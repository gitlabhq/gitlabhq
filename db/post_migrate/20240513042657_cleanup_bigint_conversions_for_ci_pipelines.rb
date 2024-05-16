# frozen_string_literal: true

class CleanupBigintConversionsForCiPipelines < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  enable_lock_retries!

  TABLE = :ci_pipelines
  COLUMNS = %i[id]

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
