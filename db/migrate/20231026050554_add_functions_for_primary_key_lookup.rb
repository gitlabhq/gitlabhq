# frozen_string_literal: true

class AddFunctionsForPrimaryKeyLookup < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  TABLES = %i[users namespaces projects].freeze

  def up
    TABLES.each do |table|
      execute <<~SQL
        CREATE OR REPLACE FUNCTION find_#{table}_by_id(#{table}_id bigint)
        RETURNS #{table} AS $$
        BEGIN
          return (SELECT #{table} FROM #{table} WHERE id = #{table}_id LIMIT 1);
        END;
        $$ LANGUAGE plpgsql STABLE PARALLEL SAFE COST 1;
      SQL
    end
  end

  def down
    TABLES.each do |table|
      execute "DROP FUNCTION IF EXISTS find_#{table}_by_id"
    end
  end
end
