# frozen_string_literal: true

class DropPrometheusAlertsForeignKeys < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  TABLE_NAME = :prometheus_alerts
  ALERTS_FK_NAME = 'fk_51ab4b6089'
  ENVIRONMENTS_FK_NAME = 'fk_rails_6d9b283465'
  METRICS_FK_NAME = 'fk_rails_e6351447ec'
  PROJECTS_FK_NAME = 'fk_rails_f0e8db86aa'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :environments,
        column: :environment_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :prometheus_metrics,
        column: :prometheus_metric_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :projects,
        column: :project_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists :alert_management_alerts, TABLE_NAME,
        column: :prometheus_alert_id
    end
  end

  # Original SQL:
  #
  # ALTER TABLE ONLY alert_management_alerts
  #     ADD CONSTRAINT fk_51ab4b6089 FOREIGN KEY (prometheus_alert_id) REFERENCES prometheus_alerts(id)
  #     ON DELETE CASCADE;
  #
  # ALTER TABLE ONLY prometheus_alerts
  #     ADD CONSTRAINT fk_rails_6d9b283465 FOREIGN KEY (environment_id) REFERENCES environments(id) ON DELETE CASCADE;
  #
  # ALTER TABLE ONLY prometheus_alerts
  #     ADD CONSTRAINT fk_rails_e6351447ec FOREIGN KEY (prometheus_metric_id) REFERENCES prometheus_metrics(id)
  #     ON DELETE CASCADE;
  #
  # ALTER TABLE ONLY prometheus_alerts
  #     ADD CONSTRAINT fk_rails_f0e8db86aa FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
  #
  def down
    add_concurrent_foreign_key :alert_management_alerts, TABLE_NAME,
      column: :prometheus_alert_id,
      name: ALERTS_FK_NAME

    add_concurrent_foreign_key TABLE_NAME, :environments,
      column: :environment_id,
      name: ENVIRONMENTS_FK_NAME

    add_concurrent_foreign_key TABLE_NAME, :prometheus_metrics,
      column: :prometheus_metric_id,
      name: METRICS_FK_NAME

    add_concurrent_foreign_key TABLE_NAME, :projects,
      column: :project_id,
      name: PROJECTS_FK_NAME
  end
end
