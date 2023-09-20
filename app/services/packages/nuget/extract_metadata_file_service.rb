# frozen_string_literal: true

module Packages
  module Nuget
    class ExtractMetadataFileService
      ExtractionError = Class.new(StandardError)

      MAX_FILE_SIZE = 4.megabytes.freeze

      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        raise ExtractionError, 'invalid package file' unless valid_package_file?

        ServiceResponse.success(payload: nuspec_file_content)
      end

      private

      attr_reader :package_file

      def valid_package_file?
        package_file &&
          package_file.package&.nuget? &&
          package_file.file.size > 0 # rubocop:disable Style/ZeroLengthPredicate
      end

      def nuspec_file_content
        with_zip_file do |zip_file|
          entry = zip_file.glob('*.nuspec').first

          raise ExtractionError, 'nuspec file not found' unless entry
          raise ExtractionError, 'nuspec file too big' if MAX_FILE_SIZE < entry.size

          Tempfile.open("nuget_extraction_package_file_#{package_file.id}") do |file|
            entry.extract(file.path) { true } # allow #extract to overwrite the file
            file.unlink
            file.read
          end
        rescue Zip::EntrySizeError => e
          raise ExtractionError, "nuspec file has the wrong entry size: #{e.message}"
        end
      end

      def with_zip_file
        package_file.file.use_open_file do |open_file|
          zip_file = Zip::File.new(open_file, false, true) # rubocop:disable Performance/Rubyzip
          yield(zip_file)
        end
      end
    end
  end
end
