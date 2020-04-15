# frozen_string_literal: true

class RemoveNotNullLfsObjectsConstraint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE lfs_objects DROP CONSTRAINT IF EXISTS lfs_objects_file_store_not_null;
      SQL
    end
  end

  def down
    # No-op
  end
end
