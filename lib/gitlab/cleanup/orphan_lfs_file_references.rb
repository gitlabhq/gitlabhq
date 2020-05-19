# frozen_string_literal: true

module Gitlab
  module Cleanup
    class OrphanLfsFileReferences
      include Gitlab::Utils::StrongMemoize

      attr_reader :project, :dry_run, :logger, :limit

      DEFAULT_REMOVAL_LIMIT = 1000

      def initialize(project, dry_run: true, logger: nil, limit: nil)
        @project = project
        @dry_run = dry_run
        @logger = logger || Rails.logger # rubocop:disable Gitlab/RailsLogger
        @limit = limit
      end

      def run!
        log_info("Looking for orphan LFS files for project #{project.name_with_namespace}")

        remove_orphan_references
      end

      private

      def remove_orphan_references
        invalid_references = project.lfs_objects_projects.where(lfs_object: orphan_objects) # rubocop:disable CodeReuse/ActiveRecord

        if dry_run
          log_info("Found invalid references: #{invalid_references.count}")
        else
          count = 0
          invalid_references.each_batch(of: limit || DEFAULT_REMOVAL_LIMIT) do |relation|
            count += relation.delete_all
          end

          ProjectCacheWorker.perform_async(project.id, [], [:lfs_objects_size])

          log_info("Removed invalid references: #{count}")
        end
      end

      def lfs_oids_from_repository
        project.repository.gitaly_blob_client.get_all_lfs_pointers.map(&:lfs_oid)
      end

      def orphan_oids
        lfs_oids_from_database - lfs_oids_from_repository
      end

      def lfs_oids_from_database
        oids = []

        project.lfs_objects.each_batch do |relation|
          oids += relation.pluck(:oid) # rubocop:disable CodeReuse/ActiveRecord
        end

        oids
      end

      def orphan_objects
        LfsObject.where(oid: orphan_oids) # rubocop:disable CodeReuse/ActiveRecord
      end

      def log_info(msg)
        logger.info("#{'[DRY RUN] ' if dry_run}#{msg}")
      end
    end
  end
end
