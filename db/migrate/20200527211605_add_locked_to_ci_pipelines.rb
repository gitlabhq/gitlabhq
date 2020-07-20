# frozen_string_literal: true

class AddLockedToCiPipelines < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :ci_pipelines, :locked, :integer, limit: 2, null: false, default: 0
    end
  end

  def down
    with_lock_retries do
      remove_column :ci_pipelines, :locked
    end
  end
end
