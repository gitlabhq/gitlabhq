# frozen_string_literal: true

class FixCustomDashboardSearchVectorTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION custom_dashboard_search_vector_update()
      RETURNS trigger AS $$
      BEGIN
        INSERT INTO custom_dashboard_search_data (
          custom_dashboard_id,
          organization_id,
          name,
          description,
          search_vector,
          created_at,
          updated_at
        )
        VALUES (
          NEW.id,
          NEW.organization_id,
          coalesce(NEW.name, ''),
          coalesce(NEW.description, ''),
          to_tsvector('english', coalesce(NEW.name, '') || ' ' || coalesce(NEW.description, '')),
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP
        )
        ON CONFLICT (custom_dashboard_id) DO UPDATE
        SET name          = EXCLUDED.name,
            description   = EXCLUDED.description,
            search_vector = EXCLUDED.search_vector,
            updated_at    = CURRENT_TIMESTAMP;

        RETURN NEW;
      END
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
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
  end
end
