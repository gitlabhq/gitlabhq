# frozen_string_literal: true

class AddOidToLfsObjectsProjects < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.1'

  SOURCE_TABLE = :lfs_objects_projects

  def up
    with_lock_retries do
      add_column SOURCE_TABLE, :oid, :text, if_not_exists: true
    end

    add_text_limit SOURCE_TABLE, :oid, 255
  end

  def down
    with_lock_retries do
      remove_column SOURCE_TABLE, :oid, if_exists: true
    end
  end
end
