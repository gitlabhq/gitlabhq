# frozen_string_literal: true

class AddShardingKeyIndexesOnNoteDiffFilesAsync < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_note_diff_files_on_namespace_id'

  milestone '18.5'

  def up
    # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/work_items/575873
    # rubocop:disable Migration/PreventIndexCreation -- Sharding key is an exception
    prepare_async_index :note_diff_files, :namespace_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index :note_diff_files, :namespace_id, name: INDEX_NAME
  end
end
