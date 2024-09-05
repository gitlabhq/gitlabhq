# frozen_string_literal: true

class DropPrometheusAlertEventsForeignKeys < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  TABLE_NAME = :prometheus_alert_events
  ALERTS_FK_NAME = 'fk_rails_106f901176'
  PROJECT_FK_NAME = 'fk_rails_4675865839'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :prometheus_alerts,
        column: :prometheus_alert_id
    end

    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :projects,
        column: :project_id
    end
  end

  # Original SQL:
  #
  # ALTER TABLE ONLY prometheus_alert_events
  #     ADD CONSTRAINT fk_rails_106f901176 FOREIGN KEY (prometheus_alert_id) REFERENCES prometheus_alerts(id)
  #     ON DELETE CASCADE;
  #
  # ALTER TABLE ONLY prometheus_alert_events
  #     ADD CONSTRAINT fk_rails_4675865839 FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
  #
  def down
    add_concurrent_foreign_key TABLE_NAME, :prometheus_alerts,
      column: :prometheus_alert_id,
      name: ALERTS_FK_NAME

    add_concurrent_foreign_key TABLE_NAME, :projects,
      column: :project_id,
      name: PROJECT_FK_NAME
  end
end
