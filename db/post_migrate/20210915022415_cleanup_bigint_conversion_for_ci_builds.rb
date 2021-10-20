# frozen_string_literal: true

class CleanupBigintConversionForCiBuilds < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  TABLE = :ci_builds
  COLUMNS = [:id, :stage_id]

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
