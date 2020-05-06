# frozen_string_literal: true

class AddDefaultValueForFileStoreToLfsObjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column_default :lfs_objects, :file_store, 1
    end
  end

  def down
    with_lock_retries do
      change_column_default :lfs_objects, :file_store, nil
    end
  end
end
