# frozen_string_literal: true

class PrepareAsyncIndexSentNotificationsNamespaceIdAndId < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'idx_sent_notifications_on_namespace_id_and_id'

  milestone '18.1'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192248
  def up
    prepare_async_index :sent_notifications, [:namespace_id, :id], name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Necessary for sharding key
  end

  def down
    unprepare_async_index :sent_notifications, [:namespace_id, :id], name: INDEX_NAME
  end
end
