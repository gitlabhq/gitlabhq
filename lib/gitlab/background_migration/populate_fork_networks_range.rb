# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This background migration is going to create all `fork_networks` and
    # the `fork_network_members` for the roots of fork networks based on the
    # existing `forked_project_links`.
    #
    # When the source of a fork is deleted, we will create the fork with the
    # target project as the root. This way, when there are forks of the target
    # project, they will be joined into the same fork network.
    #
    # When the `fork_networks` and memberships for the root projects are created
    # the `CreateForkNetworkMembershipsRange` migration is scheduled. This
    # migration will create the memberships for all remaining forks-of-forks
    class PopulateForkNetworksRange
      def perform(start_id, end_id)
        create_fork_networks_for_existing_projects(start_id, end_id)
        create_fork_networks_for_missing_projects(start_id, end_id)
        create_fork_networks_memberships_for_root_projects(start_id, end_id)

        delay = BackgroundMigration::CreateForkNetworkMembershipsRange::RESCHEDULE_DELAY # rubocop:disable Metrics/LineLength
        BackgroundMigrationWorker.perform_in(
          delay, "CreateForkNetworkMembershipsRange", [start_id, end_id]
        )
      end

      def create_fork_networks_for_existing_projects(start_id, end_id)
        log("Creating fork networks: #{start_id} - #{end_id}")
        ActiveRecord::Base.connection.execute <<~INSERT_NETWORKS
        INSERT INTO fork_networks (root_project_id)
          SELECT DISTINCT forked_project_links.forked_from_project_id

          FROM forked_project_links

          -- Exclude the forks that are not the first level fork of a project
          WHERE NOT EXISTS (
            SELECT true
            FROM forked_project_links inner_links
            WHERE inner_links.forked_to_project_id = forked_project_links.forked_from_project_id
          )

          /* Exclude the ones that are already created, in case the fork network
             was already created for another fork of the project.
          */
          AND NOT EXISTS (
            SELECT true
            FROM fork_networks
            WHERE forked_project_links.forked_from_project_id = fork_networks.root_project_id
          )

          -- Only create a fork network for a root project that still exists
          AND EXISTS (
            SELECT true
            FROM projects
            WHERE projects.id = forked_project_links.forked_from_project_id
          )
          AND forked_project_links.id BETWEEN #{start_id} AND #{end_id}
        INSERT_NETWORKS
      end

      def create_fork_networks_for_missing_projects(start_id, end_id)
        log("Creating fork networks with missing root: #{start_id} - #{end_id}")
        ActiveRecord::Base.connection.execute <<~INSERT_NETWORKS
        INSERT INTO fork_networks (root_project_id)
          SELECT DISTINCT forked_project_links.forked_to_project_id

          FROM forked_project_links

          -- Exclude forks that are not the root forks
          WHERE NOT EXISTS (
            SELECT true
            FROM forked_project_links inner_links
            WHERE inner_links.forked_to_project_id = forked_project_links.forked_from_project_id
          )

          /* Exclude the ones that are already created, in case this migration is
             re-run
          */
          AND NOT EXISTS (
            SELECT true
            FROM fork_networks
            WHERE forked_project_links.forked_to_project_id = fork_networks.root_project_id
          )

          /* Exclude projects for which the project still exists, those are
             Processed in the previous step of this migration
          */
          AND NOT EXISTS (
            SELECT true
            FROM projects
            WHERE projects.id = forked_project_links.forked_from_project_id
          )
          AND forked_project_links.id BETWEEN #{start_id} AND #{end_id}
        INSERT_NETWORKS
      end

      def create_fork_networks_memberships_for_root_projects(start_id, end_id)
        log("Creating memberships for root projects: #{start_id} - #{end_id}")

        ActiveRecord::Base.connection.execute <<~INSERT_ROOT
          INSERT INTO fork_network_members (fork_network_id, project_id)
          SELECT DISTINCT fork_networks.id, fork_networks.root_project_id

          FROM fork_networks

          /* Joining both on forked_from- and forked_to- so we could create the
             memberships for forks for which the source was deleted
          */
          INNER JOIN forked_project_links
              ON forked_project_links.forked_from_project_id = fork_networks.root_project_id
              OR forked_project_links.forked_to_project_id = fork_networks.root_project_id

          WHERE NOT EXISTS (
            SELECT true
            FROM fork_network_members
            WHERE fork_network_members.project_id = fork_networks.root_project_id
          )
          AND forked_project_links.id BETWEEN #{start_id} AND #{end_id}
        INSERT_ROOT
      end

      def log(message)
        Rails.logger.info("#{self.class.name} - #{message}")
      end
    end
  end
end
