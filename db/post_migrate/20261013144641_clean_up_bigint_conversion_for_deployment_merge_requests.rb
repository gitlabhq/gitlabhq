# frozen_string_literal: true

class CleanUpBigintConversionForDeploymentMergeRequests < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '19.6'

  TABLE = :deployment_merge_requests
  # This order produces the trigger name `trigger_b472fca0a1da`. A different
  # order produces a different name and leaves the trigger in place.
  COLUMNS = %i[deployment_id merge_request_id environment_id].freeze

  def up
    return unless can_execute_on?(TABLE)
    return if skip_bigint_migration?(TABLE, COLUMNS)
    return unless all_columns_swapped?

    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    # no-op
    #
    # Restoring the shadow columns and sync trigger reactivates the historical
    # conversion chain, whose earlier steps have empty `down` methods, so a
    # rollback past this point fails on objects they never restore.
  end

  private

  # 20260914090002 can return early without raising, which records it as
  # complete. On such an instance the shadow columns still hold the bigint
  # values, and removing them would destroy the backfill.
  def all_columns_swapped?
    swapped = COLUMNS.all? { |column| columns_swapped?(TABLE, column) }

    say 'Columns are not swapped - migration skipped' unless swapped

    swapped
  end
end
