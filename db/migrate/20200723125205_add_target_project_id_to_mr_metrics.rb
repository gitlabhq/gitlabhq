# frozen_string_literal: true

class AddTargetProjectIdToMrMetrics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :merge_request_metrics, :target_project_id, :integer
    end
  end

  def down
    with_lock_retries do
      remove_column :merge_request_metrics, :target_project_id, :integer
    end
  end
end
