# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class SelfHostedSentNotificationsCleanup < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  enable_lock_retries!
  milestone '16.10'

  TABLE = :sent_notifications
  COLUMNS = [:id]

  def up
    return if should_skip?
    return if temp_column_removed?(TABLE, COLUMNS.first)

    cleanup_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    # no-op
  end

  def should_skip?
    com_or_dev_or_test_but_not_jh?
  end
end
