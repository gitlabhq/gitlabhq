# frozen_string_literal: true

module Packages
  module TerraformModule
    class ProcessPackageFileService
      include Gitlab::Utils::StrongMemoize

      ExtractionError = Class.new(StandardError)

      def initialize(package_file)
        @package_file = package_file
      end

      def execute
        raise ExtractionError, 'invalid package file' unless valid_package_file?

        result = nil

        with_archive_file do |archive_file|
          result = ::Packages::TerraformModule::Metadata::ExtractFilesService.new(archive_file).execute
        end

        if result&.success?
          ::Packages::TerraformModule::Metadata::CreateService.new(package_file.package, result.payload).execute
        end

        ServiceResponse.success
      end

      private

      attr_reader :package_file

      def valid_package_file?
        package_file && package_file.package&.terraform_module? && !package_file.file.empty_size?
      end

      def with_archive_file(&block)
        package_file.file.use_open_file(unlink_early: false) do |open_file|
          success = process_as_gzip(open_file, &block)
          process_as_zip(open_file, &block) unless success
        end
      end

      def process_as_gzip(open_file, &block)
        Zlib::GzipReader.open(open_file.file_path) do |gzip_file|
          Gem::Package::TarReader.new(gzip_file, &block)
        end
        true
      rescue Zlib::GzipFile::Error => e
        return false if e.message == 'not in gzip format'

        raise ExtractionError, e.message
      end

      def process_as_zip(open_file, &block)
        Zip::File.open(open_file.file_path, &block) # rubocop:disable Performance/Rubyzip -- Zip::InputStream has some limitations
      rescue Zip::Error => e
        raise ExtractionError, e.message
      end
    end
  end
end
