# frozen_string_literal: true

module Packages
  module Nuget
    class MetadataExtractionService
      def initialize(package_zip_file)
        @package_zip_file = package_zip_file
      end

      def execute
        ServiceResponse.success(payload: metadata)
      end

      private

      attr_reader :package_zip_file

      def metadata
        ::Packages::Nuget::ExtractMetadataContentService
          .new(nuspec_file_content)
          .execute
          .payload
      end

      def nuspec_file_content
        ::Packages::Nuget::ExtractMetadataFileService
          .new(package_zip_file)
          .execute
          .payload
      end
    end
  end
end
