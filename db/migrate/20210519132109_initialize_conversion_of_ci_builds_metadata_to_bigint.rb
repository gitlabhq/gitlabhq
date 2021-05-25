# frozen_string_literal: true

class InitializeConversionOfCiBuildsMetadataToBigint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  TABLE = :ci_builds_metadata
  COLUMN = :build_id

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end
end
