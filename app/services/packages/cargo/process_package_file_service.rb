# frozen_string_literal: true

module Packages
  module Cargo
    class ProcessPackageFileService
      ExtractionError = Class.new(StandardError)

      def initialize(package_file, user_or_deploy_token)
        @package_file = package_file
        @user_or_deploy_token = user_or_deploy_token
      end

      def execute
        raise ExtractionError, 'invalid package file' unless valid_package_file?

        with_request_file do |request_file|
          ::Packages::Cargo::UpdatePackageFromMetadataService
            .new(@package_file, request_file, @user_or_deploy_token)
            .execute
        end
      end

      private

      def valid_package_file?
        @package_file && @package_file.package&.cargo? && !@package_file.file.empty_size?
      end

      def with_request_file
        @package_file.file.use_open_file(unlink_early: false) do |file|
          File.open(file.file_path, 'rb') do |f|
            yield f
          end
        end
      end
    end
  end
end
