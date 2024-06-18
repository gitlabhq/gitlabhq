# frozen_string_literal: true

module Packages
  module MlModel
    class CreatePackageFileService < BaseService
      def execute
        @package = params[:package]

        return unless @package

        ::Packages::Package.transaction do
          update_package
          create_package_file
        end
      end

      private

      attr_reader :package

      def update_package
        package.update_column(:status, params[:status]) if params[:status] && params[:status] != package.status

        package.create_build_infos!(params[:build])
      end

      def create_package_file
        file_params = {
          file: params[:file],
          size: params[:file].size,
          file_sha256: params[:file].sha256,
          file_name: URI.encode_uri_component(params[:file_name]),
          build: params[:build]
        }

        ::Packages::CreatePackageFileService.new(package, file_params).execute
      end
    end
  end
end
