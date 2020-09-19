# frozen_string_literal: true

class RemoveDefaultFromServices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      remove_column :services, :default, :boolean
    end
  end

  def down
    with_lock_retries do
      add_column :services, :default, :boolean, default: false
    end
  end
end
