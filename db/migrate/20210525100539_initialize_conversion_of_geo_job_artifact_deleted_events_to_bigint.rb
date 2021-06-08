# frozen_string_literal: true

class InitializeConversionOfGeoJobArtifactDeletedEventsToBigint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  TABLE = :geo_job_artifact_deleted_events
  COLUMNS = %i(job_artifact_id)

  def up
    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
