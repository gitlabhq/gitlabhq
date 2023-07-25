# frozen_string_literal: true

class PrepareNotesNamespaceIdIndex < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_notes_on_namespace_id'

  # TODO: Index to be created synchronously as part of https://gitlab.com/gitlab-org/gitlab/-/issues/416127
  def up
    prepare_async_index :notes, :namespace_id, name: INDEX_NAME
  end

  def down
    unprepare_async_index :notes, :namespace_id, name: INDEX_NAME
  end
end
