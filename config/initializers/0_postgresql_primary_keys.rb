# frozen_string_literal: true

# Adds patch for ActiveRecord `primary_keys` method
# to optimize the query for primary key retrieval.

# Rails commit: https://github.com/rails/rails/commit/c93d1b09fcc013033af506b10fd60829267be85c
# Issue: https://gitlab.com/gitlab-org/gitlab/-/work_items/579305
module PostgreSQLAdapterCustomPrimaryKeys
  if Rails.gem_version >= Gem::Version.new('8.1.0')
    raise <<~ERROR
      PostgreSQLAdapterCustomPrimaryKeys patch is no longer needed!

      This patch was a backport of a Rails 7.2.0 fix for the primary_keys method.

      Please remove this file and its associated test:
      - config/initializers/0_postgresql_primary_keys.rb
      - spec/initializers/0_postgresql_primary_keys_spec.rb

    ERROR
  end

  def primary_keys(table_name)
    query_values(<<~SQL.squish, "SCHEMA")
      SELECT a.attname
      FROM pg_index i
      JOIN pg_attribute a
        ON a.attrelid = i.indrelid
        AND a.attnum = ANY(i.indkey)
        WHERE i.indrelid = #{quote(quote_table_name(table_name))}::regclass
        AND i.indisprimary
       ORDER BY array_position(i.indkey, a.attnum)
    SQL
  end
end
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PostgreSQLAdapterCustomPrimaryKeys)
