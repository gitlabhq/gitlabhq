# frozen_string_literal: true

module Packages
  module Conan
    class PackageFilesFinder < ::Packages::PackageFilesFinder
      private

      def package_files
        files = by_conan_file_type(super)
        files = by_recipe_revision(files)
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

      def by_recipe_revision(files)
        return files unless params[:recipe_revision]

        if params[:recipe_revision] == Packages::Conan::FileMetadatum::DEFAULT_REVISION
          files.without_conan_recipe_revision
        else
          files.with_conan_recipe_revision(params[:recipe_revision])
        end
      end
    end
  end
end
