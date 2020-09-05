# frozen_string_literal: true

class AddDefaultToCiPipelineLocked < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  ARTIFACTS_LOCKED = 1
  UNLOCKED = 0

  def up
    with_lock_retries do
      change_column_default :ci_pipelines, :locked, ARTIFACTS_LOCKED
    end
  end

  def down
    with_lock_retries do
      change_column_default :ci_pipelines, :locked, UNLOCKED
    end
  end
end
