# frozen_string_literal: true

class InitializeConversionOfCiBuildsToBigint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  TABLE = :ci_builds
  COLUMNS = %i(id stage_id)
  TARGET_COLUMNS = COLUMNS.map { |col| "#{col}_convert_to_bigint" }

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
