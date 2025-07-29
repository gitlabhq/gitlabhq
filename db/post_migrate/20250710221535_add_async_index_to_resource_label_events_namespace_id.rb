# frozen_string_literal: true

class AddAsyncIndexToResourceLabelEventsNamespaceId < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_resource_label_events_on_namespace_id'

  milestone '18.3'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197676
  def up
    prepare_async_index :resource_label_events, :namespace_id, name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Sharding key is an exception
  end

  def down
    unprepare_async_index :resource_label_events, :namespace_id, name: INDEX_NAME
  end
end
