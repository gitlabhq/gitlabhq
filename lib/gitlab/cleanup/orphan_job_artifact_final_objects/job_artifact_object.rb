# frozen_string_literal: true

module Gitlab
  module Cleanup
    module OrphanJobArtifactFinalObjects
      class JobArtifactObject
        include Gitlab::Utils::StrongMemoize

        attr_reader :path, :size

        def initialize(fog_file, bucket_prefix: nil)
          @fog_file = fog_file
          @path = fog_file.key
          @size = fog_file.content_length
          @bucket_prefix = bucket_prefix
        end

        def in_final_location?
          path.include?('/@final/')
        end

        def orphan?
          !job_artifact_record_exists? && !pending_direct_upload?
        end

        def delete
          fog_file.destroy
        end

        private

        attr_reader :fog_file, :bucket_prefix

        def job_artifact_record_exists?
          ::Ci::JobArtifact.exists?(file_final_path: path_without_bucket_prefix) # rubocop:disable CodeReuse/ActiveRecord -- too simple and specific for this usecase to be its own AR method
        end

        def pending_direct_upload?
          ::ObjectStorage::PendingDirectUpload.exists?(:artifacts, path_without_bucket_prefix) # rubocop:disable CodeReuse/ActiveRecord -- `exists?` here is not the same as the AR method
        end

        def path_without_bucket_prefix
          # `path` contains the fog file's key. It is the object path relative to the artifacts bucket, for example:
          # aa/bb/abc123/@final/12/34/def12345
          #
          # But if the instance is configured to only use a single bucket combined with bucket prefixes,
          # for example if the `bucket_prefix` is "my/artifacts", the `path` would then look like:
          # my/artifacts/aa/bb/abc123/@final/12/34/def12345
          #
          # For `orphan?` to function properly, we need to strip the bucket_prefix
          # off of the `path` because we need this to match the correct job artifact record by
          # its `file_final_path` column, or the pending direct upload redis entry, which both contains
          # the object's path without `bucket_prefix`.
          #
          # If bucket_prefix is not present, this will just return the original path.
          Pathname.new(path).relative_path_from(bucket_prefix.to_s).to_s
        end
        strong_memoize_attr :path_without_bucket_prefix
      end
    end
  end
end
