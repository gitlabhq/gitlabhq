# frozen_string_literal: true

class FinalizeCiSourcesPipelinesBigintConversion < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  milestone '19.3'

  TABLE = :ci_sources_pipelines
  COLUMNS = %i[id project_id source_project_id]

  def up
    ensure_backfill_conversion_of_integer_to_bigint_is_finished(TABLE, COLUMNS)
  end

  def down
    # NO OP
  end
end
