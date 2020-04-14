# frozen_string_literal: true

class AddNotNullConstraintOnFileStoreToLfsObjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  CONSTRAINT_NAME = 'lfs_objects_file_store_not_null'
  DOWNTIME = false

  def up
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE lfs_objects ADD CONSTRAINT #{CONSTRAINT_NAME} CHECK (file_store IS NOT NULL) NOT VALID;
      SQL
    end
  end

  def down
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE lfs_objects DROP CONSTRAINT IF EXISTS #{CONSTRAINT_NAME};
      SQL
    end
  end
end
