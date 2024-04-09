# frozen_string_literal: true

class BackfillPackagesBuildInfosPipelineIdBigint < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '16.11'

  TABLE = :packages_build_infos
  COLUMN = :pipeline_id

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMN)
  end
end
