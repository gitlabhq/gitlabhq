# frozen_string_literal: true

class CreateTempIndexForBackfillingPatNotifications < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_pats_on_notification_columns_and_expires_at'
  INDEX_CONDITION = 'expire_notification_delivered IS TRUE ' \
    'AND seven_days_notification_sent_at IS NULL ' \
    'AND expires_at IS NOT NULL'

  def up
    # to be removed once BackfillPersonalAccessTokenSevenDaysNotificationSent is finalized
    # https://gitlab.com/gitlab-org/gitlab/-/issues/485856
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    add_concurrent_index :personal_access_tokens, :id, where: INDEX_CONDITION, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :personal_access_tokens, INDEX_NAME
  end
end
