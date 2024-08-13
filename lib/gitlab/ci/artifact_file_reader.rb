# frozen_string_literal: true

# This class takes in input a Ci::Build object and an artifact path to read.
# It downloads and extracts the artifacts archive, then returns the content
# of the artifact, if found.
module Gitlab
  module Ci
    class ArtifactFileReader
      Error = Class.new(StandardError)
      TMP_ARTIFACT_EXTRACTION_DIR = "extracted_artifacts_job_%{id}"

      def initialize(
        job,
        max_archive_size:)
        @job = job
        @max_archive_size = max_archive_size
        raise Error, "Job doesn't exist" unless @job
        raise Error, "Job `#{@job.name}` (#{@job.id}) does not have artifacts" unless @job.artifacts?

        validate!(max_archive_size: max_archive_size)
      end

      def read(path, max_size:)
        @max_file_size = max_size
        return unless job.artifacts_metadata

        metadata_entry = job.artifacts_metadata_entry(path)
        file_size = metadata_entry.total_size
        if file_size > max_size
          raise Error,
            "The file `#{path}` in job `#{job.name}` is too large: " \
              "#{bytes_to_human_size(file_size)} " \
              "exceeds maximum of #{bytes_to_human_size(max_size)}"
        end

        read_zip_file!(path)
      end

      private

      attr_reader :job

      def validate!(max_archive_size:)
        if job.job_artifacts_archive.size > @max_archive_size
          raise Error,
            "Artifacts archive for job `#{job.name}` is too large: " \
              "#{bytes_to_human_size(job.job_artifacts_archive.size)} " \
              "exceeds maximum of #{bytes_to_human_size(max_archive_size)}"
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

      def bytes_to_human_size(size)
        ActiveSupport::NumberHelper.number_to_human_size(size)
      end
    end
  end
end
