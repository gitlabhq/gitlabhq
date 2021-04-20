# frozen_string_literal: true

module Packages
  module Conan
    class PackageFileFinder < ::Packages::PackageFileFinder
      private

      def package_files
        files = super
        files = by_conan_file_type(files)
        by_conan_package_reference(files)
      end

      def by_conan_file_type(files)
        return files unless params[:conan_file_type]

        files.with_conan_file_type(params[:conan_file_type])
      end

      def by_conan_package_reference(files)
        return files unless params[:conan_package_reference]

        files.with_conan_package_reference(params[:conan_package_reference])
      end
    end
  end
end
