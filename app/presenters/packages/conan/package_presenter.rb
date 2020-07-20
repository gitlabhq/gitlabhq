# frozen_string_literal: true

module Packages
  module Conan
    class PackagePresenter
      include API::Helpers::RelatedResourcesHelpers
      include Gitlab::Utils::StrongMemoize

      attr_reader :params

      def initialize(recipe, user, project, params = {})
        @recipe = recipe
        @user = user
        @project = project
        @params = params
      end

      def recipe_urls
        map_package_files do |package_file|
          build_recipe_file_url(package_file) if package_file.conan_file_metadatum.recipe_file?
        end
      end

      def recipe_snapshot
        map_package_files do |package_file|
          package_file.file_md5 if package_file.conan_file_metadatum.recipe_file?
        end
      end

      def package_urls
        map_package_files do |package_file|
          next unless package_file.conan_file_metadatum.package_file? && matching_reference?(package_file)

          build_package_file_url(package_file)
        end
      end

      def package_snapshot
        map_package_files do |package_file|
          next unless package_file.conan_file_metadatum.package_file? && matching_reference?(package_file)

          package_file.file_md5
        end
      end

      private

      def build_recipe_file_url(package_file)
        expose_url(
          api_v4_packages_conan_v1_files_export_path(
            package_name: package.name,
            package_version: package.version,
            package_username: package.conan_metadatum.package_username,
            package_channel: package.conan_metadatum.package_channel,
            recipe_revision: package_file.conan_file_metadatum.recipe_revision,
            file_name: package_file.file_name
          )
        )
      end

      def build_package_file_url(package_file)
        expose_url(
          api_v4_packages_conan_v1_files_package_path(
            package_name: package.name,
            package_version: package.version,
            package_username: package.conan_metadatum.package_username,
            package_channel: package.conan_metadatum.package_channel,
            recipe_revision: package_file.conan_file_metadatum.recipe_revision,
            conan_package_reference: package_file.conan_file_metadatum.conan_package_reference,
            package_revision: package_file.conan_file_metadatum.package_revision,
            file_name: package_file.file_name
          )
        )
      end

      def map_package_files
        package_files.to_a.map do |package_file|
          key = package_file.file_name
          value = yield(package_file)
          next unless key && value

          [key, value]
        end.compact.to_h
      end

      def package_files
        return unless package

        @package_files ||= package.package_files.preload_conan_file_metadata
      end

      def package
        strong_memoize(:package) do
          name, version = @recipe.split('@')[0].split('/')

          @project.packages
                  .conan
                  .with_name(name)
                  .with_version(version)
                  .order_created
                  .last
        end
      end

      def matching_reference?(package_file)
        package_file.conan_file_metadatum.conan_package_reference == conan_package_reference
      end

      def conan_package_reference
        params[:conan_package_reference]
      end
    end
  end
end
