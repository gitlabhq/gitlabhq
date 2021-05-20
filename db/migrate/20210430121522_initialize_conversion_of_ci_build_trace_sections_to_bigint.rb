# frozen_string_literal: true

class InitializeConversionOfCiBuildTraceSectionsToBigint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  TABLE = :ci_build_trace_sections
  COLUMN = :build_id

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMN, primary_key: COLUMN)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end
end
