# frozen_string_literal: true

class DropTemporaryColumnsAndTriggersForTaggings < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  TABLE = 'taggings'
  COLUMNS = %w(id taggable_id)

  # rubocop:disable Migration/WithLockRetriesDisallowedMethod
  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod

  def down
    restore_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
