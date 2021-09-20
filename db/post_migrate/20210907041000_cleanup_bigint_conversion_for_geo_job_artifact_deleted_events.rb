# frozen_string_literal: true

class CleanupBigintConversionForGeoJobArtifactDeletedEvents < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TABLE = :geo_job_artifact_deleted_events

  # rubocop:disable Migration/WithLockRetriesDisallowedMethod
  def up
    with_lock_retries do
      cleanup_conversion_of_integer_to_bigint(TABLE, :job_artifact_id)
    end
  end
  # rubocop:enable Migration/WithLockRetriesDisallowedMethod

  def down
    restore_conversion_of_integer_to_bigint(TABLE, :job_artifact_id)
  end
end
