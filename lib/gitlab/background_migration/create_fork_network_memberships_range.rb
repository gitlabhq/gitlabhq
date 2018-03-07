# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class CreateForkNetworkMembershipsRange
      RESCHEDULE_DELAY = 15

      class ForkedProjectLink < ActiveRecord::Base
        self.table_name = 'forked_project_links'
      end

      def perform(start_id, end_id)
        log("Creating memberships for forks: #{start_id} - #{end_id}")

        insert_members(start_id, end_id)

        if missing_members?(start_id, end_id)
          BackgroundMigrationWorker.perform_in(RESCHEDULE_DELAY, "CreateForkNetworkMembershipsRange", [start_id, end_id])
        end
      end

      def insert_members(start_id, end_id)
        ActiveRecord::Base.connection.execute <<~INSERT_MEMBERS
          INSERT INTO fork_network_members (fork_network_id, project_id, forked_from_project_id)

          SELECT fork_network_members.fork_network_id,
                 forked_project_links.forked_to_project_id,
                 forked_project_links.forked_from_project_id

          FROM forked_project_links

          INNER JOIN fork_network_members
              ON forked_project_links.forked_from_project_id = fork_network_members.project_id

          WHERE forked_project_links.id BETWEEN #{start_id} AND #{end_id}
          AND NOT EXISTS (
            SELECT true
            FROM fork_network_members existing_members
            WHERE existing_members.project_id = forked_project_links.forked_to_project_id
          )
        INSERT_MEMBERS
      rescue ActiveRecord::RecordNotUnique => e
        # `fork_network_member` was created concurrently in another migration
        log(e.message)
      end

      def missing_members?(start_id, end_id)
        count_sql = <<~MISSING_MEMBERS
          SELECT COUNT(*)

          FROM forked_project_links

          WHERE NOT EXISTS (
            SELECT true
            FROM fork_network_members
            WHERE fork_network_members.project_id = forked_project_links.forked_to_project_id
          )
          AND EXISTS (
            SELECT true
            FROM projects
            WHERE forked_project_links.forked_from_project_id = projects.id
          )
          AND NOT EXISTS (
            SELECT true
            FROM forked_project_links AS parent_links
            WHERE parent_links.forked_to_project_id = forked_project_links.forked_from_project_id
            AND NOT EXISTS (
              SELECT true
              FROM projects
              WHERE parent_links.forked_from_project_id = projects.id
            )
          )
          AND forked_project_links.id BETWEEN #{start_id} AND #{end_id}
        MISSING_MEMBERS

        ForkedProjectLink.count_by_sql(count_sql) > 0
      end

      def log(message)
        Rails.logger.info("#{self.class.name} - #{message}")
      end
    end
  end
end
