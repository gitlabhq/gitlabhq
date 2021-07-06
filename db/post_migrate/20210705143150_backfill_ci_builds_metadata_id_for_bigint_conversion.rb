# frozen_string_literal: true

class BackfillCiBuildsMetadataIdForBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  TABLE = :ci_builds_metadata
  COLUMN = :id

  def up
    backfill_conversion_of_integer_to_bigint TABLE, COLUMN, batch_size: 15000, sub_batch_size: 100
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint TABLE, COLUMN
  end
end
