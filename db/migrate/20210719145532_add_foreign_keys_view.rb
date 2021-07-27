# frozen_string_literal: true

class AddForeignKeysView < ActiveRecord::Migration[6.1]
  def up
    execute(<<~SQL)
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

  def down
    execute(<<~SQL)
      DROP VIEW IF EXISTS postgres_foreign_keys
    SQL
  end
end
