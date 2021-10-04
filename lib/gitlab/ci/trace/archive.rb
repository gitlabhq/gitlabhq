# frozen_string_literal: true

module Gitlab
  module Ci
    class Trace
      class Archive
        include ::Gitlab::Utils::StrongMemoize
        include Checksummable

        def initialize(job, trace_metadata)
          @job = job
          @trace_metadata = trace_metadata
        end

        def execute!(stream)
          clone_file!(stream, JobArtifactUploader.workhorse_upload_path) do |clone_path|
            md5_checksum    = self.class.md5_hexdigest(clone_path)
            sha256_checksum = self.class.sha256_hexdigest(clone_path)

            job.transaction do
              trace_artifact = create_build_trace!(clone_path, sha256_checksum)
              trace_metadata.track_archival!(trace_artifact.id, md5_checksum)
            end
          end
        end

        private

        attr_reader :job, :trace_metadata

        def clone_file!(src_stream, temp_dir)
          FileUtils.mkdir_p(temp_dir)
          Dir.mktmpdir("tmp-trace-#{job.id}", temp_dir) do |dir_path|
            temp_path = File.join(dir_path, "job.log")
            FileUtils.touch(temp_path)
            size = IO.copy_stream(src_stream, temp_path)
            raise ::Gitlab::Ci::Trace::ArchiveError, 'Failed to copy stream' unless size == src_stream.size

            yield(temp_path)
          end
        end

        def create_build_trace!(path, file_sha256)
          File.open(path) do |stream|
            # TODO: Set `file_format: :raw` after we've cleaned up legacy traces migration
            # https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/20307
            job.create_job_artifacts_trace!(
              project: job.project,
              file_type: :trace,
              file: stream,
              file_sha256: file_sha256)
          end
        end
      end
    end
  end
end
