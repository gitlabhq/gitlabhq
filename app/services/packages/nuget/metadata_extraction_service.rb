# frozen_string_literal: true

module Packages
  module Nuget
    class MetadataExtractionService
      def initialize(package_file_id)
        @package_file_id = package_file_id
      end

      def execute
        ServiceResponse.success(payload: metadata)
      end

      private

      attr_reader :package_file_id

      def nuspec_file_content
        ExtractMetadataFileService
          .new(package_file_id)
          .execute
          .payload
      end

      def metadata
        ExtractMetadataContentService
          .new(nuspec_file_content)
          .execute
          .payload
      end
    end
  end
end
