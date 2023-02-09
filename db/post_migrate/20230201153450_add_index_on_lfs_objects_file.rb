# frozen_string_literal: true

class AddIndexOnLfsObjectsFile < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_lfs_objects_on_file'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/390401
  def up
    prepare_async_index :lfs_objects, :file, name: INDEX_NAME
  end

  def down
    unprepare_async_index :lfs_objects, :file, name: INDEX_NAME
  end
end
