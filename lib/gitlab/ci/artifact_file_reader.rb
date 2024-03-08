# frozen_string_literal: true

# This class takes in input a Ci::Build object and an artifact path to read.
# It downloads and extracts the artifacts archive, then returns the content
# of the artifact, if found.
module Gitlab
  module Ci
    class ArtifactFileReader
      Error = Class.new(StandardError)

      MAX_ARCHIVE_SIZE = 5.megabytes
      TMP_ARTIFACT_EXTRACTION_DIR = "extracted_artifacts_job_%{id}"

      def initialize(job)
        @job = job

        raise Error, "Job doesn't exist" unless @job
        raise Error, "Job `#{@job.name}` (#{@job.id}) does not have artifacts" unless @job.artifacts?

        validate!
      end

      def read(path)
        return unless job.artifacts_metadata

        metadata_entry = job.artifacts_metadata_entry(path)

        if metadata_entry.total_size > MAX_ARCHIVE_SIZE
          raise Error, "Artifacts archive for job `#{job.name}` is too large: max #{max_archive_size_in_mb}"
        end

        read_zip_file!(path)
      end

      private

      attr_reader :job

      def validate!
        if job.job_artifacts_archive.size > MAX_ARCHIVE_SIZE
          raise Error, "Artifacts archive for job `#{job.name}` is too large: max #{max_archive_size_in_mb}"
        end

        unless job.artifacts_metadata?
          raise Error, "Job `#{job.name}` (#{@job.id}) has missing artifacts metadata and cannot be extracted!"
        end
      end

      def read_zip_file!(file_path)
        dir_name = format(TMP_ARTIFACT_EXTRACTION_DIR, id: job.id.to_i)

        job.artifacts_file.use_open_file(unlink_early: false) do |tmp_open_file|
          Dir.mktmpdir(dir_name) do |tmp_dir|
            SafeZip::Extract.new(tmp_open_file.file_path).extract(files: [file_path], to: tmp_dir)
            File.read(File.join(tmp_dir, file_path))
          end
        end
      rescue SafeZip::Extract::NoMatchingError
        raise Error, "Path `#{file_path}` does not exist inside the `#{job.name}` artifacts archive!"
      rescue SafeZip::Extract::EntrySizeError
        raise Error, "Path `#{file_path}` has invalid size in the zip!"
      rescue Errno::EISDIR
        raise Error, "Path `#{file_path}` was expected to be a file but it was a directory!"
      end

      def max_archive_size_in_mb
        ActiveSupport::NumberHelper.number_to_human_size(MAX_ARCHIVE_SIZE)
      end
    end
  end
end
