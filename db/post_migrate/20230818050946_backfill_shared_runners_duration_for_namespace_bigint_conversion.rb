# frozen_string_literal: true

class BackfillSharedRunnersDurationForNamespaceBigintConversion < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  TABLE_NAME = :ci_namespace_monthly_usages
  COLUMN_NAMES = %i[shared_runners_duration]

  def up
    backfill_conversion_of_integer_to_bigint(TABLE_NAME, COLUMN_NAMES, sub_batch_size: 250)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE_NAME, COLUMN_NAMES)
  end
end
