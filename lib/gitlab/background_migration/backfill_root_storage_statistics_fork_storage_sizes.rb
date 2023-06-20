# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill the following columns on the namespace_root_storage_statistics table:
    #   - public_forks_storage_size
    #   - internal_forks_storage_size
    #   - private_forks_storage_size
    class BackfillRootStorageStatisticsForkStorageSizes < BatchedMigrationJob
      operation_name :backfill_root_storage_statistics_fork_sizes
      feature_category :consumables_cost_management

      VISIBILITY_LEVELS_TO_STORAGE_SIZE_COLUMNS = {
        0 => :private_forks_storage_size,
        10 => :internal_forks_storage_size,
        20 => :public_forks_storage_size
      }.freeze

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.each do |root_storage_statistics|
            next if has_fork_data?(root_storage_statistics)

            namespace_id = root_storage_statistics.namespace_id

            namespace_type = execute("SELECT type FROM namespaces WHERE id = #{namespace_id}").first&.fetch('type')

            next if namespace_type.nil?

            sql = if user_namespace?(namespace_type)
                    user_namespace_sql(namespace_id)
                  else
                    group_namespace_sql(namespace_id)
                  end

            stats = execute(sql)
              .map { |h| { h['projects_visibility_level'] => h['sum_project_statistics_storage_size'] } }
              .reduce({}) { |memo, h| memo.merge(h) }
              .transform_keys { |k| VISIBILITY_LEVELS_TO_STORAGE_SIZE_COLUMNS[k] }

            root_storage_statistics.update!(stats)
          end
        end
      end

      def has_fork_data?(root_storage_statistics)
        root_storage_statistics.public_forks_storage_size != 0 ||
          root_storage_statistics.internal_forks_storage_size != 0 ||
          root_storage_statistics.private_forks_storage_size != 0
      end

      def user_namespace?(type)
        type.nil? || type == 'User' || !(type == 'Group' || type == 'Project')
      end

      def execute(sql)
        ::ApplicationRecord.connection.execute(sql)
      end

      def user_namespace_sql(namespace_id)
        <<~SQL
          SELECT
            SUM("project_statistics"."storage_size") AS sum_project_statistics_storage_size,
            "projects"."visibility_level" AS projects_visibility_level
          FROM
            "projects"
            INNER JOIN "project_statistics" ON "project_statistics"."project_id" = "projects"."id"
            INNER JOIN "fork_network_members" ON "fork_network_members"."project_id" = "projects"."id"
            INNER JOIN "fork_networks" ON "fork_networks"."id" = "fork_network_members"."fork_network_id"
          WHERE
            "projects"."namespace_id" = #{namespace_id}
            AND (fork_networks.root_project_id != projects.id)
          GROUP BY "projects"."visibility_level"
        SQL
      end

      def group_namespace_sql(namespace_id)
        <<~SQL
          SELECT
            SUM("project_statistics"."storage_size") AS sum_project_statistics_storage_size,
            "projects"."visibility_level" AS projects_visibility_level
          FROM
            "projects"
            INNER JOIN "project_statistics" ON "project_statistics"."project_id" = "projects"."id"
            INNER JOIN "fork_network_members" ON "fork_network_members"."project_id" = "projects"."id"
            INNER JOIN "fork_networks" ON "fork_networks"."id" = "fork_network_members"."fork_network_id"
          WHERE
            "projects"."namespace_id" IN (
              SELECT namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)] AS id
              FROM "namespaces"
              WHERE "namespaces"."type" = 'Group' AND (traversal_ids @> ('{#{namespace_id}}'))
            )
            AND (fork_networks.root_project_id != projects.id)
          GROUP BY "projects"."visibility_level"
        SQL
      end
    end
  end
end
