# frozen_string_literal: true

class BackfillTaggingsForBigintConversion < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  TABLE = :taggings
  COLUMNS = %i(id taggable_id)

  def up
    backfill_conversion_of_integer_to_bigint TABLE, COLUMNS, batch_size: 15000, sub_batch_size: 100
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint TABLE, COLUMNS
  end
end
