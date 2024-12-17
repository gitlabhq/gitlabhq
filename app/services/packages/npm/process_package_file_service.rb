# frozen_string_literal: true

module Packages
  module Npm
    class ProcessPackageFileService
      ExtractionError = Class.new(StandardError)
      PACKAGE_JSON_ENTRY_REGEX = %r{^[^/]+/package.json$}
      MAX_FILE_SIZE = 4.megabytes

      delegate :package, to: :package_file

      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        raise ExtractionError, 'invalid package file' unless valid_package_file?

        with_package_json_entry do |entry|
          raise ExtractionError, 'package.json not found' unless entry
          raise ExtractionError, 'package.json file too large' if entry.size > MAX_FILE_SIZE

          ::Packages::Npm::CheckManifestCoherenceService.new(package, entry).execute
        end

        package.default!

        ::Packages::Npm::CreateMetadataCacheWorker.perform_async(package.project_id, package.name)

        ServiceResponse.success
      end

      private

      attr_reader :package_file

      def valid_package_file?
        package_file && !package_file.file.empty_size? && package&.processing?
      end

      def with_package_json_entry
        package_file.file.use_open_file(unlink_early: false) do |open_file|
          Zlib::GzipReader.open(open_file.file_path) do |gz|
            tar_reader = Gem::Package::TarReader.new(gz)

            entry_path = entry_full_name(tar_reader)
            yield unless entry_path.is_a?(String)

            tar_reader.rewind
            entry = tar_reader.find { |e| path_for(e) == entry_path }

            yield entry
          end
        end
      end

      def entry_full_name(tar_reader)
        # We need to reverse the entries to find the last package.json file in the tarball,
        # as the last one is the one that's used by npm.
        # We cannot get the entry directly when using #reverse_each because
        # TarReader closes the stream after iterating over all entries
        tar_reader.reverse_each do |entry|
          entry_path = path_for(entry)
          break entry_path if entry_path.match?(PACKAGE_JSON_ENTRY_REGEX)
        end
      end

      def path_for(entry)
        entry.full_name
      rescue ::Gem::Package::TarInvalidError
        entry.header.name
      end
    end
  end
end
