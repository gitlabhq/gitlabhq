# frozen_string_literal: true

module Gitlab
  module Cleanup
    class OrphanLfsFileReferences
      include Gitlab::Utils::StrongMemoize

      attr_reader :project, :dry_run, :logger

      DEFAULT_REMOVAL_LIMIT = 1000

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
        invalid_references = project.lfs_objects_projects.lfs_object_in(orphan_objects)

        if dry_run
          log_info("Found invalid references: #{invalid_references.count}")
        else
          count = 0
          invalid_references.each_batch(of: limit || DEFAULT_REMOVAL_LIMIT) do |relation|
            count += relation.delete_all
          end

          ProjectCacheWorker.perform_async(project.id, [], %w[lfs_objects_size])

          log_info("Removed invalid references: #{count}")
        end
      end

      def orphan_objects
        # Get these first so racing with a git push can't remove any LFS objects
        oids = project.lfs_objects_oids

        repos = [
          project.repository,
          project.design_repository,
          project.wiki.repository
        ].select(&:exists?)

        repos.flat_map do |repo|
          oids -= repo.gitaly_blob_client.get_all_lfs_pointers.map(&:lfs_oid)
        end

        # The remaining OIDs are not used by any repository, so are orphans
        LfsObject.for_oids(oids)
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
