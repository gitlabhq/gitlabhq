# frozen_string_literal: true

class BackfillCiSourcesPipelinesForBigintConversion < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  milestone '19.2'

  TABLE = :ci_sources_pipelines
  COLUMNS = %i[id project_id source_project_id]

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
