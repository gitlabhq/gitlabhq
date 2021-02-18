# frozen_string_literal: true

class AddAutoDeleteAtToEnvironments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :environments, :auto_delete_at, :datetime_with_timezone
    end
  end

  def down
    with_lock_retries do
      remove_column :environments, :auto_delete_at
    end
  end
end
