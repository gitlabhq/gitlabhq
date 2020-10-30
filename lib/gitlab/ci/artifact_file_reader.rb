# frozen_string_literal: true

# This class takes in input a Ci::Build object and an artifact path to read.
# It downloads and extracts the artifacts archive, then returns the content
# of the artifact, if found.
module Gitlab
  module Ci
    class ArtifactFileReader
      Error = Class.new(StandardError)

      MAX_ARCHIVE_SIZE = 5.megabytes

      def initialize(job)
        @job = job

        raise ArgumentError, 'Job does not have artifacts' unless @job.artifacts?

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
          raise Error, "Job `#{job.name}` has missing artifacts metadata and cannot be extracted!"
        end
      end

      def read_zip_file!(file_path)
        if ::Feature.enabled?(:ci_new_artifact_file_reader, job.project, default_enabled: false)
          read_with_new_artifact_file_reader(file_path)
        else
          read_with_legacy_artifact_file_reader(file_path)
        end
      end

      def read_with_new_artifact_file_reader(file_path)
        job.artifacts_file.use_open_file do |file|
          zip_file = Zip::File.new(file, false, true)
          entry = zip_file.find_entry(file_path)

          unless entry
            raise Error, "Path `#{file_path}` does not exist inside the `#{job.name}` artifacts archive!"
          end

          if entry.name_is_directory?
            raise Error, "Path `#{file_path}` was expected to be a file but it was a directory!"
          end

          zip_file.read(entry)
        end
      end

      def read_with_legacy_artifact_file_reader(file_path)
        job.artifacts_file.use_file do |archive_path|
          Zip::File.open(archive_path) do |zip_file|
            entry = zip_file.find_entry(file_path)
            unless entry
              raise Error, "Path `#{file_path}` does not exist inside the `#{job.name}` artifacts archive!"
            end

            if entry.name_is_directory?
              raise Error, "Path `#{file_path}` was expected to be a file but it was a directory!"
            end

            zip_file.get_input_stream(entry) do |is|
              is.read
            end
          end
        end
      end

      def max_archive_size_in_mb
        ActiveSupport::NumberHelper.number_to_human_size(MAX_ARCHIVE_SIZE)
      end
    end
  end
end
