# frozen_string_literal: true

class RemoveIncidentManagementPendingAlertEscProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      execute <<~SQL
        DROP TRIGGER IF EXISTS trigger_2a994bb5629f ON incident_management_pending_alert_escalations;
        DROP FUNCTION IF EXISTS trigger_2a994bb5629f();
      SQL
    end
  end

  def down
    execute <<~SQL
      CREATE FUNCTION trigger_2a994bb5629f() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
      BEGIN
      IF NEW."project_id" IS NULL THEN
        SELECT "project_id"
        INTO NEW."project_id"
        FROM "alert_management_alerts"
        WHERE "alert_management_alerts"."id" = NEW."alert_id";
      END IF;
      RETURN NEW;
      END;
      $$;

      CREATE TRIGGER trigger_2a994bb5629f
      BEFORE INSERT OR UPDATE ON incident_management_pending_alert_escalations
      FOR EACH ROW
      EXECUTE FUNCTION trigger_2a994bb5629f();
    SQL
  end
end
