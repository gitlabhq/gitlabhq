# frozen_string_literal: true

module SchemaCacheMigrationTest
  def up
    execute(<<~SQL)
      CREATE OR REPLACE VIEW postgres_foreign_keys AS
      SELECT
          pg_constraint.oid AS oid,
          pg_constraint.conname AS name,
          constrained_namespace.nspname::text || '.'::text || constrained_table.relname::text AS constrained_table_identifier,
          referenced_namespace.nspname::text || '.'::text || referenced_table.relname::text AS referenced_table_identifier,
          constrained_table.relname::text AS constrained_table_name,
          referenced_table.relname::text AS referenced_table_name,
          constrained_cols.constrained_columns,
          referenced_cols.referenced_columns,
          pg_constraint.confdeltype AS on_delete_action,
          pg_constraint.coninhcount > 0 as is_inherited
      FROM pg_constraint
               INNER JOIN pg_class constrained_table ON constrained_table.oid = pg_constraint.conrelid
               INNER JOIN pg_class referenced_table ON referenced_table.oid = pg_constraint.confrelid
               INNER JOIN pg_namespace constrained_namespace ON constrained_table.relnamespace = constrained_namespace.oid
               INNER JOIN pg_namespace referenced_namespace ON referenced_table.relnamespace = referenced_namespace.oid
               CROSS JOIN LATERAL (
                  SELECT array_agg(pg_attribute.attname ORDER BY conkey.idx) -- must order here so that attributes are in correct order in array
                  FROM unnest(pg_constraint.conkey) WITH ORDINALITY conkey(attnum, idx)
                  INNER JOIN pg_attribute ON pg_attribute.attnum = conkey.attnum AND pg_attribute.attrelid = constrained_table.oid
               ) constrained_cols(constrained_columns)
              CROSS JOIN LATERAL (
                  SELECT array_agg(pg_attribute.attname ORDER BY confkey.idx)
                  FROM unnest(pg_constraint.confkey) WITH ORDINALITY confkey(attnum, idx)
                  INNER JOIN pg_attribute ON pg_attribute.attnum = confkey.attnum AND pg_attribute.attrelid = referenced_table.oid
              ) referenced_cols(referenced_columns)
      WHERE contype = 'f';
    SQL
  end

  def down
    execute(<<~SQL)
      DROP VIEW IF EXISTS postgres_foreign_keys;
      CREATE OR REPLACE VIEW postgres_foreign_keys AS
      SELECT
          pg_constraint.oid AS oid,
          pg_constraint.conname AS name,
          constrained_namespace.nspname::text || '.'::text || constrained_table.relname::text AS constrained_table_identifier,
          referenced_namespace.nspname::text || '.'::text || referenced_table.relname::text AS referenced_table_identifier
      FROM pg_constraint
               INNER JOIN pg_class constrained_table ON constrained_table.oid = pg_constraint.conrelid
               INNER JOIN pg_class referenced_table ON referenced_table.oid = pg_constraint.confrelid
               INNER JOIN pg_namespace constrained_namespace ON constrained_table.relnamespace = constrained_namespace.oid
               INNER JOIN pg_namespace referenced_namespace ON referenced_table.relnamespace = referenced_namespace.oid
      WHERE contype = 'f';
    SQL
  end
end
