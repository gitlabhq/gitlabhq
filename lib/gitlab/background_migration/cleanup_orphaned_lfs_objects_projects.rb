# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # The migration is used to cleanup orphaned lfs_objects_projects in order to
    # introduce valid foreign keys to this table
    class CleanupOrphanedLfsObjectsProjects
      # A model to access lfs_objects_projects table in migrations
      class LfsObjectsProject < ActiveRecord::Base
        self.table_name = 'lfs_objects_projects'

        include ::EachBatch

        belongs_to :lfs_object
        belongs_to :project
      end

      # A model to access lfs_objects table in migrations
      class LfsObject < ActiveRecord::Base
        self.table_name = 'lfs_objects'
      end

      # A model to access projects table in migrations
      class Project < ActiveRecord::Base
        self.table_name = 'projects'
      end

      SUB_BATCH_SIZE = 5000
      CLEAR_CACHE_DELAY = 1.minute

      def perform(start_id, end_id)
        cleanup_lfs_objects_projects_without_lfs_object(start_id, end_id)
        cleanup_lfs_objects_projects_without_project(start_id, end_id)
      end

      private

      def cleanup_lfs_objects_projects_without_lfs_object(start_id, end_id)
        each_record_without_association(start_id, end_id, :lfs_object, :lfs_objects) do |lfs_objects_projects_without_lfs_objects|
          projects = Project.where(id: lfs_objects_projects_without_lfs_objects.select(:project_id))

          if projects.present?
            ProjectCacheWorker.bulk_perform_in_with_contexts(
              CLEAR_CACHE_DELAY,
              projects,
              arguments_proc: ->(project) { [project.id, [], [:lfs_objects_size]] },
              context_proc: ->(project) { { project: project } }
            )
          end

          lfs_objects_projects_without_lfs_objects.delete_all
        end
      end

      def cleanup_lfs_objects_projects_without_project(start_id, end_id)
        each_record_without_association(start_id, end_id, :project, :projects) do |lfs_objects_projects_without_projects|
          lfs_objects_projects_without_projects.delete_all
        end
      end

      def each_record_without_association(start_id, end_id, association, table_name)
        batch = LfsObjectsProject.where(id: start_id..end_id)

        batch.each_batch(of: SUB_BATCH_SIZE) do |sub_batch|
          first, last = sub_batch.pluck(Arel.sql('min(lfs_objects_projects.id), max(lfs_objects_projects.id)')).first

          lfs_objects_without_association =
            LfsObjectsProject
              .unscoped
              .left_outer_joins(association)
              .where(id: (first..last), table_name => { id: nil })

          yield lfs_objects_without_association
        end
      end
    end
  end
end
