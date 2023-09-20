# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Removes orphaned routes, i.e. routes that reference a namespace or project that no longer exists.
    # This was possible since we were using a polymorphic association source_id, source_type. However since now
    # we have project namespaces we can use a FK on routes#namespace_id to avoid orphaned records in routes.
    class CleanupOrphanedRoutes < Gitlab::BackgroundMigration::BatchedMigrationJob
      include Gitlab::Database::DynamicModelHelpers

      feature_category :database

      def perform
        # there should really be no records to fix, there is none gitlab.com, but taking the safer route, just in case.
        fix_missing_namespace_id_routes
        cleanup_orphaned_routes
      end

      private

      def fix_missing_namespace_id_routes
        non_orphaned_namespace_routes = non_orphaned_namespace_routes_scoped_to_range(batch_column, start_id, end_id)
        non_orphaned_project_routes = non_orphaned_project_routes_scoped_to_range(batch_column, start_id, end_id)

        update_namespace_id(batch_column, non_orphaned_namespace_routes, sub_batch_size)
        update_namespace_id(batch_column, non_orphaned_project_routes, sub_batch_size)
      end

      def cleanup_orphaned_routes
        orphaned_namespace_routes = orphaned_namespace_routes_scoped_to_range(batch_column, start_id, end_id)
        orphaned_project_routes = orphaned_project_routes_scoped_to_range(batch_column, start_id, end_id)

        cleanup_relations(batch_column, orphaned_namespace_routes, pause_ms, sub_batch_size)
        cleanup_relations(batch_column, orphaned_project_routes, pause_ms, sub_batch_size)
      end

      def update_namespace_id(batch_column, non_orphaned_namespace_routes, sub_batch_size)
        Gitlab::Database.allow_cross_joins_across_databases(
          url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046") do
          non_orphaned_namespace_routes.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
            batch_metrics.time_operation(:fix_missing_namespace_id) do
              ApplicationRecord.connection.execute <<~SQL
                WITH route_and_ns(route_id, namespace_id) AS MATERIALIZED (
                  #{sub_batch.to_sql}
                )
                UPDATE routes
                SET namespace_id = route_and_ns.namespace_id
                FROM route_and_ns
                WHERE id = route_and_ns.route_id
              SQL
            end
          end
        end
      end

      def cleanup_relations(batch_column, orphaned_namespace_routes, pause_ms, sub_batch_size)
        Gitlab::Database.allow_cross_joins_across_databases(
          url: "https://gitlab.com/gitlab-org/gitlab/-/issues/420046") do
          orphaned_namespace_routes.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
            batch_metrics.time_operation(:cleanup_orphaned_routes) do
              sub_batch.delete_all
            end
          end
        end
      end

      def orphaned_namespace_routes_scoped_to_range(source_key_column, start_id, stop_id)
        Gitlab::BackgroundMigration::Route.joins("LEFT OUTER JOIN namespaces ON source_id = namespaces.id")
          .where(source_key_column => start_id..stop_id)
          .where(source_type: 'Namespace')
          .where(namespace_id: nil)
          .where(namespaces: { id: nil })
      end

      def orphaned_project_routes_scoped_to_range(source_key_column, start_id, stop_id)
        Gitlab::BackgroundMigration::Route.joins("LEFT OUTER JOIN projects ON source_id = projects.id")
          .where(source_key_column => start_id..stop_id)
          .where(source_type: 'Project')
          .where(namespace_id: nil)
          .where(projects: { id: nil })
      end

      def non_orphaned_namespace_routes_scoped_to_range(source_key_column, start_id, stop_id)
        Gitlab::BackgroundMigration::Route.joins("LEFT OUTER JOIN namespaces ON source_id = namespaces.id")
          .where(source_key_column => start_id..stop_id)
          .where(source_type: 'Namespace')
          .where(namespace_id: nil)
          .where.not(namespaces: { id: nil })
          .select("routes.id, namespaces.id")
      end

      def non_orphaned_project_routes_scoped_to_range(source_key_column, start_id, stop_id)
        Gitlab::BackgroundMigration::Route.joins("LEFT OUTER JOIN projects ON source_id = projects.id")
          .where(source_key_column => start_id..stop_id)
          .where(source_type: 'Project')
          .where(namespace_id: nil)
          .where.not(projects: { id: nil })
          .select("routes.id, projects.project_namespace_id")
      end
    end

    # Isolated route model for the migration
    class Route < ApplicationRecord
      include EachBatch

      self.table_name = 'routes'
      self.inheritance_column = :_type_disabled
    end
  end
end
