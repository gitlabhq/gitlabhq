# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOrganizationIdOnForkNetworks < BatchedMigrationJob
      operation_name :backfill_organization_id_on_fork_networks
      feature_category :source_code_management
      scope_to ->(relation) { relation.where(organization_id: nil) }

      module Organizations
        class Organization < ::ApplicationRecord
          self.table_name = 'organizations'
        end
      end

      def perform
        # default organization id is currently 1 in the model layer
        default_organization_id = Organizations::Organization.find_by(id: 1)&.id || Organizations::Organization.first.id

        each_sub_batch do |sub_batch|
          ids = sub_batch.pluck(:id)
          next if ids.empty?

          ids_list = ids.join(',')

          connection.execute <<~SQL
            #{update_records_with_root_project_id(ids_list)}
          SQL

          connection.execute <<~SQL
            #{update_records_without_root_project_id(ids_list)}
          SQL

          connection.execute <<~SQL
            #{update_missed_records(ids_list, default_organization_id)}
          SQL
        end
      end

      private

      def update_records_with_root_project_id(ids_list)
        <<~SQL.squish
          UPDATE fork_networks
          SET organization_id = projects.organization_id
          FROM projects
          WHERE fork_networks.id IN (#{ids_list})
          AND fork_networks.root_project_id = projects.id
          AND fork_networks.organization_id IS NULL
        SQL
      end

      def update_records_without_root_project_id(ids_list)
        <<~SQL.squish
          UPDATE fork_networks
          SET organization_id = map.organization_id
          FROM (
            SELECT DISTINCT projects.organization_id, fork_networks.id
            FROM fork_networks
            JOIN fork_network_members ON fork_network_members.fork_network_id = fork_networks.id
            JOIN projects ON projects.id = fork_network_members.project_id
            WHERE fork_networks.root_project_id IS NULL
            AND fork_networks.id IN (#{ids_list})
          ) map
          WHERE map.id = fork_networks.id
        SQL
      end

      def update_missed_records(ids_list, default_organization_id)
        # we have this here just incase we miss any records
        # from the previous queries.
        <<~SQL.squish
          UPDATE fork_networks
          SET organization_id = #{default_organization_id}
          WHERE fork_networks.id IN (#{ids_list})
          AND fork_networks.organization_id IS NULL
        SQL
      end
    end
  end
end
