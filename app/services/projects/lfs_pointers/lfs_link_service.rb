# frozen_string_literal: true

# Given a list of oids, this services links the existent Lfs Objects to the project
module Projects
  module LfsPointers
    class LfsLinkService < BaseService
      TooManyOidsError = Class.new(StandardError)

      MAX_OIDS = 100_000
      BATCH_SIZE = 1000

      # Accept an array of oids to link
      #
      # Returns an array with the oid of the existent lfs objects
      def execute(oids)
        return [] unless project&.lfs_enabled?

        if oids.size > MAX_OIDS
          raise TooManyOidsError, 'Too many LFS object ids to link, please push them manually'
        end

        # Search and link existing LFS Object
        link_existing_lfs_objects(oids)
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def link_existing_lfs_objects(oids)
        linked_existing_objects = []
        iterations = 0

        oids.each_slice(BATCH_SIZE) do |oids_batch|
          # Load all existing LFS Objects immediately so we don't issue an extra
          # query for the `.any?`
          existent_lfs_objects = LfsObject.where(oid: oids_batch).load
          next unless existent_lfs_objects.any?

          rows = existent_lfs_objects
                   .not_linked_to_project(project)
                   .map { |existing_lfs_object| { project_id: project.id, lfs_object_id: existing_lfs_object.id } }
          Gitlab::Database.bulk_insert(:lfs_objects_projects, rows)
          iterations += 1

          linked_existing_objects += existent_lfs_objects.map(&:oid)
        end

        log_lfs_link_results(linked_existing_objects.count, iterations)

        linked_existing_objects
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def log_lfs_link_results(lfs_objects_linked_count, iterations)
        Gitlab::Import::Logger.info(
          class: self.class.name,
          project_id: project.id,
          project_path: project.full_path,
          lfs_objects_linked_count: lfs_objects_linked_count,
          iterations: iterations)
      end
    end
  end
end
