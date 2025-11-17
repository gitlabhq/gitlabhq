# frozen_string_literal: true

class AddCustomDashboardSearchVectorTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION custom_dashboard_search_vector_update()
      RETURNS trigger AS $$
      BEGIN
        INSERT INTO custom_dashboard_search_data (
          custom_dashboard_id,
          organization_id,
          search_vector,
          created_at,
          updated_at
        )
        VALUES (
          NEW.id,
          NEW.organization_id,
          to_tsvector('english', NEW.name || ' ' || NEW.description),
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP
        )
        ON CONFLICT (custom_dashboard_id) DO UPDATE
        SET search_vector = EXCLUDED.search_vector,
            updated_at = CURRENT_TIMESTAMP;

        RETURN NEW;
      END
      $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL
      DROP TRIGGER IF EXISTS custom_dashboard_search_vector_trigger ON custom_dashboards;
    SQL

    execute <<~SQL
      CREATE TRIGGER custom_dashboard_search_vector_trigger
      AFTER INSERT OR UPDATE OF name, description ON custom_dashboards
      FOR EACH ROW
      EXECUTE FUNCTION custom_dashboard_search_vector_update();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS custom_dashboard_search_vector_trigger ON custom_dashboards;
      DROP FUNCTION IF EXISTS custom_dashboard_search_vector_update();
    SQL
  end
end
