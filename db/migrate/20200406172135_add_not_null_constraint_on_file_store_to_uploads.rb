# frozen_string_literal: true

class AddNotNullConstraintOnFileStoreToUploads < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  CONSTRAINT_NAME = 'uploads_store_not_null'
  DOWNTIME = false

  def up
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE uploads ADD CONSTRAINT #{CONSTRAINT_NAME} CHECK (store IS NOT NULL) NOT VALID;
      SQL
    end
  end

  def down
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE uploads DROP CONSTRAINT IF EXISTS #{CONSTRAINT_NAME};
      SQL
    end
  end
end
