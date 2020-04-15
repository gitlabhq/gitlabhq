# frozen_string_literal: true

class RemoveNotNullUploadsConstraint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE uploads DROP CONSTRAINT IF EXISTS uploads_store_not_null;
      SQL
    end
  end

  def down
    # No-op
  end
end
