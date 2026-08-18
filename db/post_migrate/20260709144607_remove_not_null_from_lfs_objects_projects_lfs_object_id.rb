# frozen_string_literal: true

class RemoveNotNullFromLfsObjectsProjectsLfsObjectId < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def up
    change_column_null :lfs_objects_projects, :lfs_object_id, true
  end

  def down
    # No-op: re-adding a NOT NULL constraint on this high-traffic, over-limit
    # table is unsafe, and rows replicated during org migration may legitimately
    # have a NULL lfs_object_id.
  end
end
