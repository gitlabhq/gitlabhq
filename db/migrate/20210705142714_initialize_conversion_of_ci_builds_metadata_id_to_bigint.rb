# frozen_string_literal: true

class InitializeConversionOfCiBuildsMetadataIdToBigint < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  TABLE = :ci_builds_metadata
  COLUMN = :id

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end
end
