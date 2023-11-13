# frozen_string_literal: true

module Packages
  module Nuget
    class ExtractMetadataFileService
      ExtractionError = Class.new(StandardError)

      MAX_FILE_SIZE = 4.megabytes.freeze

      def initialize(package_zip_file)
        @package_zip_file = package_zip_file
      end

      def execute
        ServiceResponse.success(payload: nuspec_file_content)
      end

      private

      attr_reader :package_zip_file

      def nuspec_file_content
        entry = extract_nuspec_file

        raise ExtractionError, 'nuspec file not found' unless entry
        raise ExtractionError, 'nuspec file too big' if MAX_FILE_SIZE < entry.size

        Tempfile.create('nuget_extraction_package_file') do |file|
          entry.extract(file.path) { true } # allow #extract to overwrite the file
          file.read
        end
      rescue Zip::EntrySizeError => e
        raise ExtractionError, "nuspec file has the wrong entry size: #{e.message}"
      end

      def extract_nuspec_file
        if package_zip_file.is_a?(Zip::InputStream)
          while (entry = package_zip_file.get_next_entry) # rubocop:disable Lint/AssignmentInCondition -- Following https://github.com/rubyzip/rubyzip#notes-on-zipinputstream and that's why the disable rubocop rule
            break entry if entry.name.end_with?('.nuspec')
          end
        else
          package_zip_file.glob('*.nuspec').first
        end
      end
    end
  end
end
