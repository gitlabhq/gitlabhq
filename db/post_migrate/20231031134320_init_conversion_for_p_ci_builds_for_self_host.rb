# frozen_string_literal: true

class InitConversionForPCiBuildsForSelfHost < Gitlab::Database::Migration[2.2]
  include ::Gitlab::Database::SchemaHelpers

  milestone '16.6'
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
  TRIGGER_NAME = :trigger_10ee1357e825

  def up
    return if should_skip?

    initialize_conversion_of_integer_to_bigint(TABLE_NAME, COLUMN_NAMES)
  end

  def down
    return unless should_skip?

    revert_initialize_conversion_of_integer_to_bigint(TABLE_NAME, COLUMN_NAMES)
  end

  private

  def should_skip?
    trigger_exists?(TABLE_NAME, TRIGGER_NAME)
  end
end
