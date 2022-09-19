# frozen_string_literal: true

class AddConstraintsView < Gitlab::Database::Migration[2.0]
  def up
    execute(<<~SQL)
    CREATE OR REPLACE VIEW postgres_constraints
    AS
    SELECT
      pg_constraint.oid AS oid,
      pg_constraint.conname AS name,
      pg_constraint.contype AS constraint_type,
      pg_constraint.convalidated AS constraint_valid,
      (SELECT array_agg(attname ORDER BY ordering)
        FROM unnest(pg_constraint.conkey) WITH ORDINALITY attnums(attnum, ordering)
        INNER JOIN pg_attribute ON pg_attribute.attnum = attnums.attnum AND pg_attribute.attrelid = pg_class.oid
      ) AS column_names,
      pg_namespace.nspname::text || '.'::text || pg_class.relname::text AS table_identifier,
      -- pg_constraint reports a 0 oid rather than null if the constraint is not a partition child constraint.
      nullif(pg_constraint.conparentid, 0) AS parent_constraint_oid,
      pg_get_constraintdef(pg_constraint.oid) AS definition
    FROM pg_constraint
    INNER JOIN pg_class ON pg_constraint.conrelid = pg_class.oid
    INNER JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid;
    SQL
  end

  def down
    execute(<<~SQL)
      DROP VIEW postgres_constraints;
    SQL
  end
end
