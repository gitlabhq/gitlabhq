# frozen_string_literal: true

class AddOrganizationScopedPrimaryKeyLookupFunctions < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  TABLES = %i[users namespaces projects].freeze

  def up
    TABLES.each do |table|
      execute <<~SQL
        CREATE OR REPLACE FUNCTION find_#{table}_by_id_and_organization_id(#{table}_id bigint, sharding_organization_id bigint)
        RETURNS #{table} AS $$
        BEGIN
          return (SELECT #{table} FROM #{table} WHERE id = #{table}_id AND organization_id = sharding_organization_id LIMIT 1);
        END;
        $$ LANGUAGE plpgsql STABLE PARALLEL SAFE COST 1;
      SQL
    end
  end

  def down
    TABLES.each do |table|
      execute "DROP FUNCTION IF EXISTS find_#{table}_by_id_and_organization_id"
    end
  end
end
