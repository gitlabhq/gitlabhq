# frozen_string_literal: true

class AsyncAddIndexOnEventsPersonalNamespaceId2 < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  INDEX_NAME = 'index_events_on_personal_namespace_id'

  # -- https://gitlab.com/gitlab-org/gitlab/-/issues/462801#note_2081632603
  def up
    return unless Gitlab.com_except_jh?

    prepare_async_index :events, :personal_namespace_id, name: INDEX_NAME, # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
      where: 'personal_namespace_id IS NOT NULL'
  end

  def down
    return unless Gitlab.com_except_jh?

    unprepare_async_index :events, INDEX_NAME
  end
end
