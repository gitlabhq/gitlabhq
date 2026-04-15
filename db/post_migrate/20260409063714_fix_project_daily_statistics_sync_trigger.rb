# frozen_string_literal: true

class FixProjectDailyStatisticsSyncTrigger < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!
  milestone '18.8'

  def up
    Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
      execute(<<~SQL)
        CREATE OR REPLACE FUNCTION table_sync_function_c237afdf68()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $$
        BEGIN
          IF (TG_OP = 'DELETE') THEN
            DELETE FROM project_daily_statistics_archived WHERE "id" = OLD."id";
          ELSIF (TG_OP = 'UPDATE') THEN
            UPDATE project_daily_statistics_archived
            SET "project_id" = NEW."project_id",
                "fetch_count" = NEW."fetch_count",
                "date" = NEW."date"
            WHERE project_daily_statistics_archived."id" = NEW."id";
          ELSIF (TG_OP = 'INSERT') THEN
            INSERT INTO project_daily_statistics_archived ("id", "project_id", "fetch_count", "date")
            VALUES (NEW."id", NEW."project_id", NEW."fetch_count", NEW."date")
            ON CONFLICT ("project_id", "date") DO NOTHING;
          END IF;
          RETURN NULL;
        END
        $$;
      SQL
    end
  end

  def down
    Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
      execute(<<~SQL)
        CREATE OR REPLACE FUNCTION table_sync_function_c237afdf68()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $$
        BEGIN
        IF (TG_OP = 'DELETE') THEN
          DELETE FROM project_daily_statistics_archived where "id" = OLD."id";
        ELSIF (TG_OP = 'UPDATE') THEN
          UPDATE project_daily_statistics_archived
          SET "project_id" = NEW."project_id",
            "fetch_count" = NEW."fetch_count",
            "date" = NEW."date"
          WHERE project_daily_statistics_archived."id" = NEW."id";
        ELSIF (TG_OP = 'INSERT') THEN
          INSERT INTO project_daily_statistics_archived ("id",
            "project_id",
            "fetch_count",
            "date")
          VALUES (NEW."id",
            NEW."project_id",
            NEW."fetch_count",
            NEW."date");
        END IF;
        RETURN NULL;

        END
        $$;
      SQL
    end
  end
end
