# frozen_string_literal: true

class CleanUpBigintConversionForCiSourcesPipelines < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  TABLE = :ci_sources_pipelines
  COLUMNS = %i[id project_id source_project_id]

  def up
    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    # no-op. Restoring the columns and trigger would reactivate a conversion
    # chain whose finalize step has an empty `down`, so a rollback past this
    # point cannot complete.
  end
end
