# frozen_string_literal: true

class AddDefaultValueForStoreToUploads < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column_default :uploads, :store, 1
    end
  end

  def down
    with_lock_retries do
      change_column_default :uploads, :store, nil
    end
  end
end
