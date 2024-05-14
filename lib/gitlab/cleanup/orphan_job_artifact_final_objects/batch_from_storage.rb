# frozen_string_literal: true

module Gitlab
  module Cleanup
    module OrphanJobArtifactFinalObjects
      class BatchFromStorage
        def initialize(fog_collection, bucket_prefix: nil)
          @fog_collection = fog_collection
          @bucket_prefix = bucket_prefix
        end

        def orphan_objects
          objects = {}

          fog_collection.each_file_this_page do |fog_file|
            next unless in_final_location?(fog_file.key)

            objects[path_without_bucket_prefix(fog_file.key)] = fog_file
          end

          return [] unless objects.any?

          # First we exclude all objects that have matching existing job artifact record in the DB
          paths_with_job_artifact_records(objects.keys).each do |non_orphan_path|
            objects.delete(non_orphan_path)
          end

          return [] unless objects.any?

          # Next, if there were no matching job artifact record for the remaining paths, we want to
          # check if there is a pending direct upload for the given path, if found, they are not considered orphans.
          paths_with_pending_direct_uploads(objects.keys).each do |non_orphan_path|
            objects.delete(non_orphan_path)
          end

          # Just to keep the lexicographic order of objects
          objects.values.sort_by(&:key)
        end

        private

        attr_reader :fog_collection, :bucket_prefix

        def path_without_bucket_prefix(path)
          # `path` contains the fog file's key. It is the object path relative to the artifacts bucket, for example:
          # aa/bb/abc123/@final/12/34/def12345
          #
          # But if the instance is configured to only use a single bucket combined with bucket prefixes,
          # for example if the `bucket_prefix` is "my/artifacts", the `path` would then look like:
          # my/artifacts/aa/bb/abc123/@final/12/34/def12345
          #
          # To correctly identify orphan objects, we need to strip the bucket_prefix
          # off of the `path` because we need this to match the correct job artifact record by
          # its `file_final_path` column, or the pending direct upload redis entry, which both contains
          # the object's path without `bucket_prefix`.
          #
          # If bucket_prefix is not present, this will just return the original path.
          Pathname.new(path).relative_path_from(bucket_prefix.to_s).to_s
        end

        def in_final_location?(path)
          path.include?('/@final/')
        end

        def paths_with_job_artifact_records(paths)
          ::Ci::JobArtifact.where(file_final_path: paths).pluck(:file_final_path) # rubocop:disable CodeReuse/ActiveRecord -- intentionally used pluck directly to keep it simple.
        end

        def paths_with_pending_direct_uploads(paths)
          ::ObjectStorage::PendingDirectUpload.with_pending_only(:artifacts, paths)
        end
      end
    end
  end
end
