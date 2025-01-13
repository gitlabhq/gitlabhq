# frozen_string_literal: true

module Types
  module Packages
    class PackageBaseType < ::Types::BaseObject
      graphql_name 'PackageBase'
      description 'Represents a package in the Package Registry'

      PROTECTION_RULE_EXISTS_BATCH_SIZE = 20

      connection_type_class Types::CountableConnectionType

      authorize :read_package

      expose_permissions Types::PermissionTypes::Package

      field :id, ::Types::GlobalIDType[::Packages::Package], null: false, description: 'ID of the package.'

      field :_links, Types::Packages::PackageLinksType, null: false, method: :itself,
        description: 'Map of links to perform actions on the package.'
      field :created_at, Types::TimeType, null: false, description: 'Date of creation.'
      field :metadata, Types::Packages::MetadataType,
        null: true,
        description: 'Package metadata.'
      field :name, GraphQL::Types::String, null: false, description: 'Name of the package.'
      field :package_type, Types::Packages::PackageTypeEnum, null: false, description: 'Package type.'
      field :project, Types::ProjectType, null: false, description: 'Project where the package is stored.'
      field :protection_rule_exists, GraphQL::Types::Boolean,
        null: false,
        description: 'Whether any matching package protection rule exists for the package.'
      field :status, Types::Packages::PackageStatusEnum, null: false, description: 'Package status.'
      field :status_message, GraphQL::Types::String, null: true, description: 'Status message.'
      field :tags, Types::Packages::PackageTagType.connection_type, null: true, description: 'Package tags.'
      field :updated_at, Types::TimeType, null: false, description: 'Date of most recent update.'
      field :version, GraphQL::Types::String, null: true, description: 'Version string.'

      def project
        Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
      end

      def protection_rule_exists
        object_package_type_value = ::Packages::Package.package_types[object.package_type]

        BatchLoader::GraphQL.for([object.project_id, object.name, object_package_type_value]).batch do |tuples, loader|
          tuples.each_slice(PROTECTION_RULE_EXISTS_BATCH_SIZE) do |projects_and_packages|
            ::Packages::Protection::Rule
              .for_push_exists_for_projects_and_packages(projects_and_packages)
              .each do |row|
                loader.call([row['project_id'], row['package_name'], row['package_type']], row['protected'])
              end
          end
        end
      end

      # NOTE: This method must be kept in sync with the union
      # type: `Types::Packages::MetadataType`.
      #
      # `Types::Packages::MetadataType.resolve_type(metadata, ctx)` must never raise.
      # rubocop: disable GraphQL/ResolverMethodLength
      def metadata
        case object.package_type
        when 'composer'
          object.composer_metadatum
        when 'conan'
          object.conan_metadatum
        when 'maven'
          object.maven_metadatum
        when 'nuget'
          object.nuget_metadatum
        when 'pypi'
          object.pypi_metadatum
        when 'terraform_module'
          object.terraform_module_metadatum
        end
      end
      # rubocop: enable GraphQL/ResolverMethodLength
    end
  end
end
