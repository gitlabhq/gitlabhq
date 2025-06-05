# frozen_string_literal: true

class DropTmpOnNotificationAndExpiredAtOnPatIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.1'

  INDEX_NAME = 'tmp_index_pats_on_notification_columns_and_expires_at'

  def up
    remove_concurrent_index_by_name(:personal_access_tokens, INDEX_NAME)
  end

  def down
    add_concurrent_index(
      :personal_access_tokens, [:id],
      where: 'expire_notification_delivered IS TRUE AND ' \
        'seven_days_notification_sent_at IS NULL AND ' \
        'expires_at IS NOT NULL',
      name: INDEX_NAME
    )
  end
end
