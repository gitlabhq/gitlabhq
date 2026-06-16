# frozen_string_literal: true

class AddCiConfigGeneratedByToCiProjectMetrics < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :ci_project_metrics, :ci_config_generated_by, :text, null: true, if_not_exists: true
    end

    add_text_limit :ci_project_metrics, :ci_config_generated_by, 255
  end

  def down
    with_lock_retries do
      remove_column :ci_project_metrics, :ci_config_generated_by, if_exists: true
    end
  end
end
