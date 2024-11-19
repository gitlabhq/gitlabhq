# frozen_string_literal: true

module Types
  module Packages
    class PackageDetailsType < PackageType
      graphql_name 'PackageDetailsType'
      description 'Represents a package details in the Package Registry'

      include ::PackagesHelper

      authorize :read_package

      field :versions, ::Types::Packages::PackageBaseType.connection_type, null: true,
        description: 'Other versions of the package.'

      field :package_files,
        Types::Packages::PackageFileType.connection_type,
        null: true,
        method: :installable_package_files,
        description: 'Package files.'

      field :dependency_links, Types::Packages::PackageDependencyLinkType.connection_type, null: true,
        description: 'Dependency link.'

      field :composer_config_repository_url, GraphQL::Types::String, null: true,
        description: 'Url of the Composer setup endpoint.'
      field :composer_url, GraphQL::Types::String, null: true, description: 'Url of the Composer endpoint.'
      field :conan_url, GraphQL::Types::String, null: true, description: 'Url of the Conan project endpoint.'
      field :maven_url, GraphQL::Types::String, null: true, description: 'Url of the Maven project endpoint.'
      field :npm_url, GraphQL::Types::String, null: true, description: 'Url of the NPM project endpoint.'
      field :nuget_url, GraphQL::Types::String, null: true, description: 'Url of the Nuget project endpoint.'
      field :pypi_setup_url, GraphQL::Types::String, null: true, description: 'Url of the PyPi project setup endpoint.'
      field :pypi_url, GraphQL::Types::String, null: true, description: 'Url of the PyPi project endpoint.'

      field :last_downloaded_at, Types::TimeType, null: true,
        description: 'Last time that a file of this package was downloaded.'

      field :public_package, GraphQL::Types::Boolean, null: true,
        description: 'Indicates if there is public access to the package.'

      def composer_config_repository_url
        composer_config_repository_name(object.project.group&.id)
      end

      def composer_url
        composer_registry_url(object.project.group&.id)
      end

      def conan_url
        package_registry_project_url(object.project.id, :conan)
      end

      def maven_url
        package_registry_project_url(object.project.id, :maven)
      end

      def npm_url
        package_registry_project_url(object.project.id, :npm)
      end

      def nuget_url
        nuget_package_registry_url(object.project.id)
      end

      def pypi_setup_url
        package_registry_project_url(object.project.id, :pypi)
      end

      def pypi_url
        pypi_registry_url(object.project)
      end

      def public_package
        object.project.project_feature.public_packages?
      end
    end
  end
end
