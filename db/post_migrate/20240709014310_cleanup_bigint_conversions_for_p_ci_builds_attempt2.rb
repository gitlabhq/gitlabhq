# frozen_string_literal: true

class CleanupBigintConversionsForPCiBuildsAttempt2 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::SchemaHelpers

  milestone '17.3'

  enable_lock_retries!

  TABLE_NAME = :p_ci_builds
  TRIGGER_NAME = :trigger_10ee1357e825
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
    return unless trigger_and_integer_columns_exists?

    lock_tables(TABLE_NAME, mode: :access_exclusive, only: true)
    lock_tables(TABLE_NAME, mode: :access_exclusive)
    cleanup_conversion_of_integer_to_bigint(TABLE_NAME, COLUMN_NAMES)
  end

  def down
    return if trigger_and_integer_columns_exists?

    restore_conversion_of_integer_to_bigint(TABLE_NAME, COLUMN_NAMES)
  end

  private

  def trigger_and_integer_columns_exists?
    trigger_exists?(TABLE_NAME, TRIGGER_NAME) && \
      COLUMN_NAMES.all? { |name| column_exists?(TABLE_NAME, "#{name}_convert_to_bigint") }
  end
end
