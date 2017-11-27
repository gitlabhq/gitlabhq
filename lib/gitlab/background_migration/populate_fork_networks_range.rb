# frozen_string_literal: true
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/LineLength
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class PopulateForkNetworksRange
      def perform(start_id, end_id)
        log("Creating fork networks for forked project links: #{start_id} - #{end_id}")

        ActiveRecord::Base.connection.execute <<~INSERT_NETWORKS
        INSERT INTO fork_networks (root_project_id)
          SELECT DISTINCT forked_project_links.forked_from_project_id

          FROM forked_project_links

          WHERE NOT EXISTS (
            SELECT true
            FROM forked_project_links inner_links
            WHERE inner_links.forked_to_project_id = forked_project_links.forked_from_project_id
          )
          AND NOT EXISTS (
            SELECT true
            FROM fork_networks
            WHERE forked_project_links.forked_from_project_id = fork_networks.root_project_id
          )
          AND EXISTS (
            SELECT true
            FROM projects
            WHERE projects.id = forked_project_links.forked_from_project_id
          )
          AND forked_project_links.id BETWEEN #{start_id} AND #{end_id}
        INSERT_NETWORKS

        log("Creating memberships for root projects: #{start_id} - #{end_id}")

        ActiveRecord::Base.connection.execute <<~INSERT_ROOT
          INSERT INTO fork_network_members (fork_network_id, project_id)
          SELECT DISTINCT fork_networks.id, fork_networks.root_project_id

          FROM fork_networks

          INNER JOIN forked_project_links
              ON forked_project_links.forked_from_project_id = fork_networks.root_project_id

          WHERE NOT EXISTS (
            SELECT true
            FROM fork_network_members
            WHERE fork_network_members.project_id = fork_networks.root_project_id
          )
          AND forked_project_links.id BETWEEN #{start_id} AND #{end_id}
        INSERT_ROOT

        delay = BackgroundMigration::CreateForkNetworkMembershipsRange::RESCHEDULE_DELAY
        BackgroundMigrationWorker.perform_in(delay, "CreateForkNetworkMembershipsRange", [start_id, end_id])
      end

      def log(message)
        Rails.logger.info("#{self.class.name} - #{message}")
      end
    end
  end
end
