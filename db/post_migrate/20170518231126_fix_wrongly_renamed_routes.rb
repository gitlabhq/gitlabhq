# rubocop:disable Migration/UpdateLargeTable
# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FixWronglyRenamedRoutes < ActiveRecord::Migration
  include Gitlab::Database::RenameReservedPathsMigration::V1

  DOWNTIME = false

  disable_ddl_transaction!

  DISALLOWED_ROOT_PATHS = %w[
    -
    abuse_reports
    api
    autocomplete
    explore
    health_check
    import
    invites
    jwt
    koding
    member
    notification_settings
    oauth
    sent_notifications
    unicorn_test
    uploads
    users
  ]

  FIXED_PATHS = DISALLOWED_ROOT_PATHS.map { |p| "#{p}0" }

  class Route < Gitlab::Database::RenameReservedPathsMigration::V1::MigrationClasses::Route
    self.table_name = 'routes'
  end

  def routes
    @routes ||= Route.arel_table
  end

  def namespaces
    @namespaces ||= Arel::Table.new(:namespaces)
  end

  def wildcard_collection(collection)
    collection.map { |word| "#{word}%" }
  end

  # The routes that got incorrectly renamed before, still have a namespace that
  # contains the correct path.
  # This query fetches all rows from the `routes` table that meet the following
  # conditions using `api` as an example:
  # - route.path ILIKE `api0%`
  # - route.source_type = `Namespace`
  # - namespace.parent_id IS NULL
  # - namespace.path ILIKE `api%`
  # - NOT(namespace.path ILIKE `api0%`)
  # This gives us all root-routes, that were renamed, but their namespace was not.
  #
  def wrongly_renamed
    Route.joins("INNER JOIN namespaces ON routes.source_id = namespaces.id")
      .where(
        routes[:source_type].eq('Namespace')
          .and(namespaces[:parent_id].eq(nil))
      )
      .where(namespaces[:path].matches_any(wildcard_collection(DISALLOWED_ROOT_PATHS)))
      .where.not(namespaces[:path].matches_any(wildcard_collection(FIXED_PATHS)))
      .where(routes[:path].matches_any(wildcard_collection(FIXED_PATHS)))
  end

  # Using the query above, we just fetch the `route.path` & the `namespace.path`
  # `route.path` is the part of the route that is now incorrect
  # `namespace.path` is what it should be
  # We can use `route.path` to find all the namespaces that need to be fixed
  # And we can use `namespace.path` to apply the correct name.
  #
  def paths_and_corrections
    connection.select_all(
      wrongly_renamed.select(routes[:path], namespaces[:path].as('namespace_path')).to_sql
    )
  end

  # This can be used to limit the `update_in_batches` call to all routes for a
  # single namespace, note the `/` that's what went wrong in the initial migration.
  #
  def routes_in_namespace_query(namespace)
    routes[:path].matches_any([namespace, "#{namespace}/%"])
  end

  def up
    paths_and_corrections.each do |root_namespace|
      wrong_path = root_namespace['path']
      correct_path = root_namespace['namespace_path']
      replace_statement = replace_sql(Route.arel_table[:path], wrong_path, correct_path)

      update_column_in_batches(:routes, :path, replace_statement) do |table, query|
        query.where(routes_in_namespace_query(wrong_path))
      end
    end
  end

  def down
  end
end
