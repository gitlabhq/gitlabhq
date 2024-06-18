# frozen_string_literal: true

module Packages
  module Npm
    class ProcessPackageFileService
      ExtractionError = Class.new(StandardError)
      PACKAGE_JSON_ENTRY_PATH = '*/package.json'
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
        end

        package.default!

        ::Packages::Npm::CreateMetadataCacheWorker.perform_async(package.project_id, package.name)

        ServiceResponse.success
      end

      private

      attr_reader :package_file

      def valid_package_file?
        package_file && !package_file.file.empty_size? && package&.npm? && package&.processing?
      end

      def with_package_json_entry
        package_file.file.use_open_file(unlink_early: false) do |open_file|
          Zlib::GzipReader.open(open_file.file_path) do |gz|
            entry = Gem::Package::TarReader.new(gz).find { |e| File.fnmatch(PACKAGE_JSON_ENTRY_PATH, e.full_name) }
            yield entry
          end
        end
      end
    end
  end
end
