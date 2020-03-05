# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Create missing LfsObjectsProject records for forks
    class LinkLfsObjects
      # Model definition used for migration
      class ForkNetworkMember < ActiveRecord::Base
        include EachBatch

        self.table_name = 'fork_network_members'

        def self.with_non_existing_lfs_objects
          joins('JOIN lfs_objects_projects lop ON fork_network_members.forked_from_project_id = lop.project_id')
            .where(
              <<~SQL
                NOT EXISTS (
                  SELECT 1
                  FROM lfs_objects_projects
                  WHERE lfs_objects_projects.project_id = fork_network_members.project_id
                  AND lfs_objects_projects.lfs_object_id = lop.lfs_object_id
                )
              SQL
            )
        end
      end

      # Model definition used for migration
      class Project < ActiveRecord::Base
        include EachBatch

        self.table_name = 'projects'

        has_one :fork_network_member, class_name: 'LinkLfsObjects::ForkNetworkMember'

        def self.with_non_existing_lfs_objects
          fork_network_members =
            ForkNetworkMember.with_non_existing_lfs_objects
              .select(1)
              .where('fork_network_members.project_id = projects.id')

          where('EXISTS (?)', fork_network_members)
        end
      end

      # Model definition used for migration
      class LfsObjectsProject < ActiveRecord::Base
        include EachBatch

        self.table_name = 'lfs_objects_projects'
      end

      BATCH_SIZE = 1000

      def perform(start_id, end_id)
        forks =
          Project
            .with_non_existing_lfs_objects
            .where(id: start_id..end_id)

        forks.includes(:fork_network_member).find_each do |project|
          LfsObjectsProject
            .select("lfs_objects_projects.lfs_object_id, #{project.id}, NOW(), NOW()")
            .where(project_id: project.fork_network_member.forked_from_project_id)
            .each_batch(of: BATCH_SIZE) do |batch|
              execute <<~SQL
                INSERT INTO lfs_objects_projects (lfs_object_id, project_id, created_at, updated_at)
                #{batch.to_sql}
              SQL
            end
        end

        logger.info(message: "LinkLfsObjects: created missing LfsObjectsProject for Projects #{forks.map(&:id).join(', ')}")
      end

      private

      def execute(sql)
        ::ActiveRecord::Base.connection.execute(sql)
      end

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end
    end
  end
end
