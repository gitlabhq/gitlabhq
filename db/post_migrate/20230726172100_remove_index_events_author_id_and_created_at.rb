# frozen_string_literal: true

class RemoveIndexEventsAuthorIdAndCreatedAt < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_events_on_author_id_and_created_at_merge_requests'

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127657
  def up
    prepare_async_index_removal :events,
      [:author_id, :created_at],
      name: INDEX_NAME
  end

  def down
    unprepare_async_index :events,
      [:author_id, :created_at],
      name: INDEX_NAME
  end
end
