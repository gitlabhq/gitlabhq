# frozen_string_literal: true

class PrepareAsyncIndexSentNotificationsNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  INDEX_NAME = 'index_sent_notifications_on_namespace_id'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/work_items/541120
  def up
    prepare_async_index :sent_notifications, :namespace_id, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Necessary for sharding key
  end

  def down
    unprepare_async_index :sent_notifications, :namespace_id, name: INDEX_NAME
  end
end
