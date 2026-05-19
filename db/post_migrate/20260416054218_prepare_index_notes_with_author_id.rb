# frozen_string_literal: true

class PrepareIndexNotesWithAuthorId < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  INDEX_NAME = 'index_notes_on_noteable_id_and_noteable_type_system_author_id'
  COLUMNS = [:noteable_id, :noteable_type, :system]

  def up
    # Follow-up issue to create index https://gitlab.com/gitlab-org/gitlab/-/work_items/595599
    prepare_async_index :notes, COLUMNS, name: INDEX_NAME, include: [:author_id] # rubocop:disable Migration/PreventIndexCreation -- exception granted in https://gitlab.com/gitlab-org/database-team/team-tasks/-/work_items/606
  end

  def down
    unprepare_async_index_by_name :notes, INDEX_NAME
  end
end
