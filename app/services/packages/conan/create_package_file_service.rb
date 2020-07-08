# frozen_string_literal: true

module Packages
  module Conan
    class CreatePackageFileService
      attr_reader :package, :file, :params

      def initialize(package, file, params)
        @package = package
        @file = file
        @params = params
      end

      def execute
        package.package_files.create!(
          file:      file,
          size:      params['file.size'],
          file_name: params[:file_name],
          file_sha1: params['file.sha1'],
          file_md5:  params['file.md5'],
          conan_file_metadatum_attributes: {
            recipe_revision: params[:recipe_revision],
            package_revision: params[:package_revision],
            conan_package_reference: params[:conan_package_reference],
            conan_file_type: params[:conan_file_type]
          }
        )
      end
    end
  end
end
