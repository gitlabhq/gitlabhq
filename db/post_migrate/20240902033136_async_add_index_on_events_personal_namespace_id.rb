# frozen_string_literal: true

class AsyncAddIndexOnEventsPersonalNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  INDEX_NAME = 'index_events_on_personal_namespace_id'

  # rubocop:disable Migration/PreventIndexCreation -- https://gitlab.com/gitlab-org/gitlab/-/issues/462801#note_2081632603
  def up
    prepare_async_index :events, :personal_namespace_id, name: INDEX_NAME,
      where: 'personal_namespace_id IS NOT NULL'
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    unprepare_async_index :events, INDEX_NAME
  end
end
