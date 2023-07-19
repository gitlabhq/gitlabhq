# frozen_string_literal: true

class BackfillCiPipelineVariablesForPipelineIdBigintConversion < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  TABLE = :ci_pipeline_variables
  COLUMNS = %i[pipeline_id]

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS, sub_batch_size: 500)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
