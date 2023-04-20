# frozen_string_literal: true

class PrepareAsyncSentNotificationsIndex < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  TABLE_NAME = :sent_notifications
  COLUMN_NAME = :id_convert_to_bigint
  INDEX_NAME = :index_sent_notifications_on_id_convert_to_bigint

  def up
    return unless should_run?

    prepare_async_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME, unique: true
  end

  def down
    return unless should_run?

    unprepare_async_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME
  end

  private

  def should_run?
    com_or_dev_or_test_but_not_jh?
  end
end
