# frozen_string_literal: true

class BackfillCiBuildsForBigintConversion < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  TABLE = :ci_builds
  COLUMNS = %i(id stage_id).freeze

  def up
    return unless should_run?

    backfill_conversion_of_integer_to_bigint TABLE, COLUMNS, batch_size: 15000, sub_batch_size: 100
  end

  def down
    return unless should_run?

    revert_backfill_conversion_of_integer_to_bigint TABLE, COLUMNS
  end

  private

  def should_run?
    Gitlab.dev_or_test_env? || Gitlab.com?
  end
end
