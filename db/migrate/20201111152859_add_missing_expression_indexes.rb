# frozen_string_literal: true

class AddMissingExpressionIndexes < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEXES = [
    [:namespaces, :index_on_namespaces_lower_name, 'LOWER(name)'],
    [:namespaces, :index_on_namespaces_lower_path, 'LOWER(path)'],
    [:projects, :index_on_projects_lower_path, 'LOWER(path)'],
    [:routes, :index_on_routes_lower_path, 'LOWER(path)'],
    [:users, :index_on_users_lower_username, 'LOWER(username)'],
    [:users, :index_on_users_lower_email, 'LOWER(email)']
  ]

  def up
    # Those indexes had been introduced before, but they haven't been
    # captured in structure.sql. For installations that already have it,
    # this is a no-op - others will get it retroactively with
    # this migration.

    tables = Set.new

    INDEXES.each do |(table, name, expression)|
      unless index_name_exists?(table, name)
        add_concurrent_index table, expression, name: name
        tables.add(table)
      end
    end

    # Rebuild statistics on affected tables only
    tables.each do |table|
      execute("ANALYZE #{table}")
    end
  end

  def down
    # no-op
  end
end
