# frozen_string_literal: true

module Packages
  module Debian
    class CreatePackageFileService
      def initialize(package, params)
        @package = package
        @params = params
      end

      def execute
        raise ArgumentError, "Invalid package" unless package.present?

        # Debian package file are first uploaded to incoming with empty metadata,
        # and are moved later by Packages::Debian::ProcessChangesService
        package.package_files.create!(
          file:        params[:file],
          size:        params[:file]&.size,
          file_name:   params[:file_name],
          file_sha1:   params[:file_sha1],
          file_sha256: params[:file]&.sha256,
          file_md5:    params[:file_md5],
          debian_file_metadatum_attributes: {
            file_type: 'unknown',
            architecture: nil,
            fields: nil
          }
        )
      end

      private

      attr_reader :package, :params
    end
  end
end
