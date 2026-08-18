# frozen_string_literal: true

class FixProjectAuthorizationsSyncTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION sync_project_authorizations_to_migration_table() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
      IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        INSERT INTO project_authorizations_for_migration (project_id, user_id, access_level)
        VALUES (NEW.project_id, NEW.user_id, NEW.access_level::smallint)
        ON CONFLICT (project_id, user_id) DO UPDATE
          SET access_level = NEW.access_level::smallint;
        RETURN NEW;

      ELSIF (TG_OP = 'DELETE') THEN
        WITH remaining AS (
          SELECT project_id, user_id, MIN(access_level)::smallint AS access_level
          FROM project_authorizations
          WHERE project_id = OLD.project_id AND user_id = OLD.user_id
          GROUP BY project_id, user_id
        ), upsert AS (
          INSERT INTO project_authorizations_for_migration (project_id, user_id, access_level)
          SELECT project_id, user_id, access_level
          FROM remaining
          ON CONFLICT (project_id, user_id) DO UPDATE
            SET access_level = EXCLUDED.access_level
        )
        DELETE FROM project_authorizations_for_migration
        WHERE project_id = OLD.project_id AND user_id = OLD.user_id
          AND NOT EXISTS (SELECT 1 FROM remaining);
        RETURN OLD;
      END IF;

      RETURN NULL;

      END
      $$;
    SQL
  end

  def down
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION sync_project_authorizations_to_migration_table() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
      IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        INSERT INTO project_authorizations_for_migration (project_id, user_id, access_level)
        VALUES (NEW.project_id, NEW.user_id, NEW.access_level::smallint)
        ON CONFLICT (project_id, user_id) DO UPDATE
          SET access_level = NEW.access_level::smallint;
        RETURN NEW;

      ELSIF (TG_OP = 'DELETE') THEN
        DELETE FROM project_authorizations_for_migration
        WHERE project_id = OLD.project_id AND user_id = OLD.user_id;
        RETURN OLD;
      END IF;

      RETURN NULL;

      END
      $$;
    SQL
  end
end
