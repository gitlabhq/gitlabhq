# frozen_string_literal: true

module Packages
  module Debian
    class CreatePackageFileService
      def initialize(package:, current_user:, params: {})
        @package = package
        @current_user = current_user
        @params = params
      end

      def execute
        raise ArgumentError, "Invalid package" unless package.present?
        raise ArgumentError, "Invalid user" unless current_user.present?

        # Debian package file are first uploaded to incoming with empty metadata,
        # and are moved later by Packages::Debian::ProcessPackageFileService
        package_file = package.package_files.create!(
          file: params[:file],
          size: params[:file]&.size,
          file_name: params[:file_name],
          file_sha1: params[:file_sha1],
          file_sha256: params[:file]&.sha256,
          file_md5: params[:file_md5],
          debian_file_metadatum_attributes: {
            file_type: 'unknown',
            architecture: nil,
            fields: nil
          }
        )

        if end_of_new_upload?
          ::Packages::Debian::ProcessPackageFileWorker.perform_async(
            package_file.id,
            params[:distribution],
            params[:component]
          )
        end

        package_file
      end

      private

      attr_reader :package, :current_user, :params

      def end_of_new_upload?
        params[:distribution].present? || params[:file_name].end_with?('.changes')
      end
    end
  end
end
