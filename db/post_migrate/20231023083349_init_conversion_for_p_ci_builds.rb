# frozen_string_literal: true

class InitConversionForPCiBuilds < Gitlab::Database::Migration[2.1]
  include ::Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!

  TABLE_NAME = :p_ci_builds
  COLUMN_NAMES = %i[
    auto_canceled_by_id
    commit_id
    erased_by_id
    project_id
    runner_id
    trigger_request_id
    upstream_pipeline_id
    user_id
  ]

  def up
    return if should_skip?

    initialize_conversion_of_integer_to_bigint(TABLE_NAME, COLUMN_NAMES)
  end

  def down
    return if should_skip?

    revert_initialize_conversion_of_integer_to_bigint(TABLE_NAME, COLUMN_NAMES)
  end

  private

  def should_skip?
    !can_execute_on?(TABLE_NAME)
  end
end
