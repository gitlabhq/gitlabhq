# frozen_string_literal: true

module Packages
  module Conan
    class PackagePresenter
      include API::Helpers::Packages::Conan::ApiHelpers
      include API::Helpers::RelatedResourcesHelpers
      include Gitlab::Utils::StrongMemoize

      attr_reader :params

      def initialize(package, user, project, params = {})
        @package = package
        @user = user
        @project = project
        @params = params
      end

      def recipe_urls
        map_package_files do |package_file|
          next unless package_file.conan_file_metadatum.recipe_file?

          options = url_options(package_file)
          recipe_file_url(options)
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

          options = url_options(package_file).merge(
            conan_package_reference: package_file.conan_file_metadatum.conan_package_reference,
            package_revision: package_file.conan_file_metadatum.package_revision_value
          )

          package_file_url(options)
        end
      end

      def package_snapshot
        map_package_files do |package_file|
          next unless package_file.conan_file_metadatum.package_file? && matching_reference?(package_file)

          package_file.file_md5
        end
      end

      private

      def url_options(package_file)
        {
          package_name: @package.name,
          package_version: @package.version,
          package_username: @package.conan_metadatum.package_username,
          package_channel: @package.conan_metadatum.package_channel,
          file_name: package_file.file_name,
          recipe_revision: package_file.conan_file_metadatum.recipe_revision_value
        }
      end

      def map_package_files
        package_files.to_a.map do |package_file|
          next unless package_file.conan_file_metadatum

          key = package_file.file_name
          value = yield(package_file)
          next unless key && value

          [key, value]
        end.compact.to_h
      end

      def package_files
        return unless @package

        @package.installable_package_files.preload_conan_file_metadata
      end
      strong_memoize_attr :package_files

      def matching_reference?(package_file)
        package_file.conan_file_metadatum.conan_package_reference == conan_package_reference
      end

      def conan_package_reference
        params[:conan_package_reference]
      end
    end
  end
end
