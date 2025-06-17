# frozen_string_literal: true

module Packages
  module Nuget
    class ProcessPackageFileService
      ExtractionError = Class.new(StandardError)

      def initialize(package_file, user_or_deploy_token = nil)
        @package_file = package_file
        @user_or_deploy_token = user_or_deploy_token
      end

      def execute
        raise ExtractionError, 'invalid package file' unless valid_package_file?

        with_zip_file do |zip_file|
          ::Packages::Nuget::UpdatePackageFromMetadataService
            .new(package_file, zip_file, user_or_deploy_token)
            .execute
        end
      end

      private

      attr_reader :package_file, :user_or_deploy_token

      def valid_package_file?
        package_file && package_file.package&.nuget? && !package_file.file.empty_size?
      end

      def with_zip_file(&block)
        package_file.file.use_open_file(unlink_early: false) do |open_file|
          Zip::File.open(open_file.file_path, &block) # rubocop: disable Performance/Rubyzip
        end
      end
    end
  end
end
