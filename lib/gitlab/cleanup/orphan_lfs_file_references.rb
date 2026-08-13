# frozen_string_literal: true

module Gitlab
  module Cleanup
    class OrphanLfsFileReferences
      include Gitlab::Utils::StrongMemoize

      attr_reader :project, :dry_run, :logger

      DEFAULT_REMOVAL_LIMIT = 1000
      OID_BATCH_SIZE = 1000

      def initialize(project, dry_run: true, logger: nil)
        @project = project
        @dry_run = dry_run
        @logger = logger || Gitlab::AppLogger
      end

      def run!
        log_info("Looking for orphan LFS files for project #{project.name_with_namespace}")

        if project.lfs_objects.empty?
          log_info("Project #{project.name_with_namespace} is linked to 0 LFS objects. Nothing to do")
          return
        end

        remove_orphan_references
      end

      private

      def remove_orphan_references
        count = orphan_oids.each_slice(OID_BATCH_SIZE).sum do |oids_batch|
          process_slice(invalid_references(oids_batch))
        end

        if dry_run
          log_info("Found invalid references: #{count}")
        else
          ProjectCacheWorker.perform_async(project.id, [], %w[lfs_objects_size])

          log_info("Removed invalid references: #{count}")
        end
      end

      def process_slice(references)
        return references.count if dry_run

        deleted = 0

        references.each_batch(of: limit || DEFAULT_REMOVAL_LIMIT) do |relation|
          deleted += relation.delete_all
        end

        deleted
      end

      def invalid_references(oids)
        lfs_object_ids = LfsObject.for_oids(oids).pluck_primary_key

        project.lfs_objects_projects.lfs_object_in(lfs_object_ids)
      end

      def orphan_oids
        # Get these first so racing with a git push can't remove any LFS objects
        oids = project.lfs_objects_oids

        repos = [
          project.repository,
          project.design_repository,
          project.wiki.repository
        ].select(&:exists?)

        repos.each do |repo|
          oids -= repo.gitaly_blob_client.get_all_lfs_pointers.map(&:lfs_oid)
        end

        # The remaining OIDs are not used by any repository, so are orphans
        oids
      end

      def log_info(msg)
        logger.info("#{'[DRY RUN] ' if dry_run}#{msg}")
      end

      def limit
        ENV['LIMIT']&.to_i
      end
    end
  end
end
