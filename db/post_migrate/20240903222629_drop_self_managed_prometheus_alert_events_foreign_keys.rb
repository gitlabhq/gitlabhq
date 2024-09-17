# frozen_string_literal: true

class DropSelfManagedPrometheusAlertEventsForeignKeys < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  TABLE_NAME = :self_managed_prometheus_alert_events
  PROJECTS_FK_NAME = 'fk_rails_3936dadc62'
  ENVIRONMENTS_FK_NAME = 'fk_rails_39d83d1b65'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :projects,
        column: :project_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :environments,
        column: :environment_id
    end
  end

  # Original SQL:
  #
  # ALTER TABLE ONLY self_managed_prometheus_alert_events
  #     ADD CONSTRAINT fk_rails_3936dadc62 FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
  #
  # ALTER TABLE ONLY self_managed_prometheus_alert_events
  #     ADD CONSTRAINT fk_rails_39d83d1b65 FOREIGN KEY (environment_id) REFERENCES environments(id) ON DELETE CASCADE;
  #
  def down
    add_concurrent_foreign_key TABLE_NAME, :projects,
      column: :project_id,
      name: PROJECTS_FK_NAME

    add_concurrent_foreign_key TABLE_NAME, :environments,
      column: :environment_id,
      name: ENVIRONMENTS_FK_NAME
  end
end
