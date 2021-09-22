# frozen_string_literal: true

class CleanupBigintConversionForCiBuildsMetadata < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  TABLE = :ci_builds_metadata

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, :id)
    cleanup_conversion_of_integer_to_bigint(TABLE, :build_id)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, :build_id)
    restore_conversion_of_integer_to_bigint(TABLE, :id)
  end
end
