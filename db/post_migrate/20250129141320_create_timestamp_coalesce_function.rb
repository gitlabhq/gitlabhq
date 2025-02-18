# frozen_string_literal: true

class CreateTimestampCoalesceFunction < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  FUNCTION_NAME = 'timestamp_coalesce(t1 TIMESTAMPTZ, t2 ANYELEMENT)'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{FUNCTION_NAME}
      RETURNS TIMESTAMP AS $$
      BEGIN
        RETURN COALESCE(t1::TIMESTAMP, t2);
      END;
      $$ LANGUAGE plpgsql IMMUTABLE;
    SQL
  end

  def down
    execute(<<~SQL)
      DROP FUNCTION IF EXISTS #{FUNCTION_NAME}
    SQL
  end
end
