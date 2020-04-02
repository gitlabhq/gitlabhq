# frozen_string_literal: true

class RemoveHealthStatusFromEpics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      remove_column :epics, :health_status
    end
  end

  def down
    with_lock_retries do
      add_column :epics, :health_status, :integer, limit: 2
    end
  end
end
