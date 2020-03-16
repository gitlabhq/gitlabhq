# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Create missing LfsObjectsProject records for forks
    class LinkLfsObjectsProjects
      # Model specifically used for migration.
      class LfsObjectsProject < ActiveRecord::Base
        include EachBatch

        self.table_name = 'lfs_objects_projects'

        def self.linkable
          where(
            <<~SQL
              lfs_objects_projects.project_id IN (
                SELECT fork_network_members.forked_from_project_id
                FROM fork_network_members
                WHERE fork_network_members.forked_from_project_id IS NOT NULL
              )
            SQL
          )
        end
      end

      # Model specifically used for migration.
      class ForkNetworkMember < ActiveRecord::Base
        include EachBatch

        self.table_name = 'fork_network_members'

        def self.without_lfs_object(lfs_object_id)
          where(
            <<~SQL
              fork_network_members.project_id NOT IN (
                SELECT lop.project_id
                FROM lfs_objects_projects lop
                WHERE lop.lfs_object_id = #{lfs_object_id}
              )
            SQL
          )
        end
      end

      BATCH_SIZE = 1000

      def perform(start_id, end_id)
        lfs_objects_projects =
          Gitlab::BackgroundMigration::LinkLfsObjectsProjects::LfsObjectsProject
            .linkable
            .where(id: start_id..end_id)

        return if lfs_objects_projects.empty?

        lfs_objects_projects.find_each do |lop|
          ForkNetworkMember
            .select("#{lop.lfs_object_id}, fork_network_members.project_id, NOW(), NOW()")
            .without_lfs_object(lop.lfs_object_id)
            .where(forked_from_project_id: lop.project_id)
            .each_batch(of: BATCH_SIZE) do |batch, index|
              execute <<~SQL
                INSERT INTO lfs_objects_projects (lfs_object_id, project_id, created_at, updated_at)
                #{batch.to_sql}
              SQL

              logger.info(message: "LinkLfsObjectsProjects: created missing LfsObjectsProject records for LfsObject #{lop.lfs_object_id}")
            end
        end
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
