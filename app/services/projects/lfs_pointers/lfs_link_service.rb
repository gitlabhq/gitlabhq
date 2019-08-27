# frozen_string_literal: true

# Given a list of oids, this services links the existent Lfs Objects to the project
module Projects
  module LfsPointers
    class LfsLinkService < BaseService
      BATCH_SIZE = 1000

      # Accept an array of oids to link
      #
      # Returns an array with the oid of the existent lfs objects
      def execute(oids)
        return [] unless project&.lfs_enabled?

        # Search and link existing LFS Object
        link_existing_lfs_objects(oids)
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def link_existing_lfs_objects(oids)
        all_existing_objects = []
        iterations = 0

        LfsObject.where(oid: oids).each_batch(of: BATCH_SIZE) do |existent_lfs_objects|
          next unless existent_lfs_objects.any?

          iterations += 1
          not_linked_lfs_objects = existent_lfs_objects.where.not(id: project.all_lfs_objects)
          project.all_lfs_objects << not_linked_lfs_objects

          all_existing_objects += existent_lfs_objects.pluck(:oid)
        end

        log_lfs_link_results(all_existing_objects.count, iterations)

        all_existing_objects
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
