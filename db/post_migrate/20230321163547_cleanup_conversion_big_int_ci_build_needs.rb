# frozen_string_literal: true

class CleanupConversionBigIntCiBuildNeeds < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  TABLE = :ci_build_needs

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, :id)
  end

  def down
    restore_conversion_of_integer_to_bigint(TABLE, :id)
  end
end
