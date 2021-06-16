# frozen_string_literal: true

class BackfillCiStagesForBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  TABLE = :ci_stages
  COLUMNS = %i(id)

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
