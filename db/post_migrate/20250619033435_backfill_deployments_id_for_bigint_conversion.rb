# frozen_string_literal: true

class BackfillDeploymentsIdForBigintConversion < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.2'

  TABLE = :deployments
  COLUMNS = %i[id environment_id project_id user_id]

  def up
    backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS, sub_batch_size: 200)
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end
end
