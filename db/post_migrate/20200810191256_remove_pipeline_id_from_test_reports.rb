# frozen_string_literal: true

class RemovePipelineIdFromTestReports < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    remove_column :requirements_management_test_reports, :pipeline_id
  end

  def down
    add_column :requirements_management_test_reports, :pipeline_id, :integer

    with_lock_retries do
      add_foreign_key :requirements_management_test_reports, :ci_pipelines, column: :pipeline_id, on_delete: :nullify
    end
  end
end
