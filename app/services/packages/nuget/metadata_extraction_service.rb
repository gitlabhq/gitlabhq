# frozen_string_literal: true

module Packages
  module Nuget
    class MetadataExtractionService
      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        ServiceResponse.success(payload: metadata)
      end

      private

      attr_reader :package_file

      def metadata
        ExtractMetadataContentService
          .new(nuspec_file_content)
          .execute
          .payload
      end

      def nuspec_file_content
        ExtractMetadataFileService
          .new(package_file)
          .execute
          .payload
      end
    end
  end
end
