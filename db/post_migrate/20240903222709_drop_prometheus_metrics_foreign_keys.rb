# frozen_string_literal: true

class DropPrometheusMetricsForeignKeys < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  TABLE_NAME = :prometheus_metrics
  PROJECT_FK_NAME = 'fk_rails_4c8957a707'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :projects,
        column: :project_id
    end
  end

  # Original SQL:
  #
  # ALTER TABLE ONLY prometheus_metrics
  #     ADD CONSTRAINT fk_rails_4c8957a707 FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
  #
  def down
    add_concurrent_foreign_key TABLE_NAME, :projects,
      column: :project_id,
      name: PROJECT_FK_NAME
  end
end
