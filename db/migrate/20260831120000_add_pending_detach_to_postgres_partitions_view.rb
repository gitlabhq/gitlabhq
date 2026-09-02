# frozen_string_literal: true

class AddPendingDetachToPostgresPartitionsView < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def up
    # Recommended to drop the view before recreating it
    execute('DROP VIEW IF EXISTS postgres_partitions;')

    # A partition left behind by an interrupted DETACH ... CONCURRENTLY keeps relispartition, so the
    # view cannot distinguish it from an attached one. We expose inhdetachpending so callers can.
    execute(<<~SQL)
      CREATE OR REPLACE VIEW postgres_partitions AS
      SELECT
        pg_namespace.nspname::text || '.'::text || pg_class.relname::text AS identifier,
        pg_class.oid,
        pg_namespace.nspname AS schema,
        pg_class.relname AS name,
        parent_namespace.nspname::text || '.'::text || parent_class.relname::text AS parent_identifier,
        pg_get_expr(pg_class.relpartbound, pg_inherits.inhrelid) AS condition,
        pg_inherits.inhdetachpending AS pending_detach
      FROM pg_class
      INNER JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
      INNER JOIN pg_inherits ON pg_class.oid = pg_inherits.inhrelid
      INNER JOIN pg_class parent_class ON pg_inherits.inhparent = parent_class.oid
      INNER JOIN pg_namespace parent_namespace ON parent_class.relnamespace = parent_namespace.oid
      WHERE pg_class.relispartition
        AND pg_namespace.nspname IN (current_schema(), 'gitlab_partitions_dynamic', 'gitlab_partitions_static');
    SQL
  end

  def down
    # CREATE OR REPLACE VIEW cannot drop a column, so the view is recreated.
    execute('DROP VIEW IF EXISTS postgres_partitions;')

    execute(<<~SQL)
      CREATE VIEW postgres_partitions AS
      SELECT
        pg_namespace.nspname::text || '.'::text || pg_class.relname::text AS identifier,
        pg_class.oid,
        pg_namespace.nspname AS schema,
        pg_class.relname AS name,
        parent_namespace.nspname::text || '.'::text || parent_class.relname::text AS parent_identifier,
        pg_get_expr(pg_class.relpartbound, pg_inherits.inhrelid) AS condition
      FROM pg_class
      INNER JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
      INNER JOIN pg_inherits ON pg_class.oid = pg_inherits.inhrelid
      INNER JOIN pg_class parent_class ON pg_inherits.inhparent = parent_class.oid
      INNER JOIN pg_namespace parent_namespace ON parent_class.relnamespace = parent_namespace.oid
      WHERE pg_class.relispartition
        AND pg_namespace.nspname IN (current_schema(), 'gitlab_partitions_dynamic', 'gitlab_partitions_static');
    SQL
  end
end
