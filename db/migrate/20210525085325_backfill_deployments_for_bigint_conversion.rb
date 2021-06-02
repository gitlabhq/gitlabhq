# frozen_string_literal: true

class BackfillDeploymentsForBigintConversion < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  TABLE = :deployments
  COLUMNS = %i(deployable_id)

  def up
    backfill_conversion_of_integer_to_bigint TABLE, COLUMNS
  end

  def down
    revert_backfill_conversion_of_integer_to_bigint TABLE, COLUMNS
  end
end
