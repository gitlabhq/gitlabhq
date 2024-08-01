# frozen_string_literal: true

class UpdatePostgresSequencesView < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE VIEW postgres_sequences
      AS
      SELECT seq_pg_class.relname AS seq_name,
             dep_pg_class.relname AS table_name,
             pg_attribute.attname AS col_name
      FROM pg_class seq_pg_class
           INNER JOIN pg_depend ON seq_pg_class.oid = pg_depend.objid
           INNER JOIN pg_class dep_pg_class ON pg_depend.refobjid = dep_pg_class.oid
           INNER JOIN pg_attribute ON dep_pg_class.oid = pg_attribute.attrelid
                                   AND pg_depend.refobjsubid = pg_attribute.attnum
      WHERE pg_depend.classid = 'pg_class'::regclass
        AND pg_depend.refclassid = 'pg_class'::regclass
        AND seq_pg_class.relkind = 'S'
    SQL
  end

  def down
    execute(<<~SQL)
      CREATE OR REPLACE VIEW postgres_sequences
      AS
      SELECT seq_pg_class.relname AS seq_name,
          dep_pg_class.relname AS table_name,
          pg_attribute.attname AS col_name
        FROM pg_class seq_pg_class
        INNER JOIN pg_depend ON seq_pg_class.oid = pg_depend.objid
        INNER JOIN pg_class dep_pg_class ON pg_depend.refobjid = dep_pg_class.oid
        INNER JOIN pg_attribute ON dep_pg_class.oid = pg_attribute.attrelid
        AND pg_depend.refobjsubid = pg_attribute.attnum
        WHERE seq_pg_class.relkind = 'S'
    SQL
  end
end
