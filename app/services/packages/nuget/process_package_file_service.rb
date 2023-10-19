# frozen_string_literal: true

module Packages
  module Nuget
    class ProcessPackageFileService
      ExtractionError = Class.new(StandardError)
      NUGET_SYMBOL_FILE_EXTENSION = '.snupkg'

      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        raise ExtractionError, 'invalid package file' unless valid_package_file?

        nuspec_content = nil

        with_zip_file do |zip_file|
          nuspec_content = nuspec_file_content(zip_file)
          create_symbol_files(zip_file) if symbol_package_file?
        end

        ServiceResponse.success(payload: { nuspec_file_content: nuspec_content })
      end

      private

      attr_reader :package_file

      def valid_package_file?
        package_file &&
          package_file.package&.nuget? &&
          package_file.file.size > 0 # rubocop:disable Style/ZeroLengthPredicate
      end

      def with_zip_file(&block)
        package_file.file.use_open_file(unlink_early: false) do |open_file|
          Zip::File.open(open_file.file_path, &block) # rubocop: disable Performance/Rubyzip
        end
      end

      def nuspec_file_content(zip_file)
        ::Packages::Nuget::ExtractMetadataFileService
          .new(zip_file)
          .execute
          .payload
      end

      def create_symbol_files(zip_file)
        ::Packages::Nuget::Symbols::CreateSymbolFilesService
          .new(package_file.package, zip_file)
          .execute
      end

      def symbol_package_file?
        package_file.file_name.end_with?(NUGET_SYMBOL_FILE_EXTENSION)
      end
    end
  end
end
