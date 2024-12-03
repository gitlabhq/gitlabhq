# frozen_string_literal: true

# -- update an existing index
class UpdateSentNotificationsIndexOnNoteable < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  INDEX_NAME = 'index_sent_notifications_on_noteable_type_noteable_id_and_id'
  COLUMN_NAMES = %i[noteable_id id]

  # Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/502841
  #
  # This is designed to replace existing index:
  # "index_sent_notifications_on_noteable_type_noteable_id" btree (noteable_id) WHERE noteable_type = 'Issue'
  # with
  # "index_sent_notifications_on_noteable_type_noteable_id_id" btree (noteable_id, id) WHERE noteable_type = 'Issue'
  # to improve iterating over issue related sent notification records in batches.
  def up
    # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
    prepare_async_index :sent_notifications, COLUMN_NAMES, where: "noteable_type = 'Issue'", name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index :sent_notifications, COLUMN_NAMES, name: INDEX_NAME
  end
end
