# frozen_string_literal: true

module Types
  module Packages
    class PackageBaseType < ::Types::BaseObject
      graphql_name 'PackageBase'
      description 'Represents a package in the Package Registry'

      connection_type_class Types::CountableConnectionType

      authorize :read_package

      expose_permissions Types::PermissionTypes::Package

      field :id, ::Types::GlobalIDType[::Packages::Package], null: false, description: 'ID of the package.'

      field :_links, Types::Packages::PackageLinksType, null: false, method: :itself,
                                                        description: 'Map of links to perform actions on the package.'
      field :can_destroy, GraphQL::Types::Boolean,
        null: false,
        deprecated: {
          reason: 'Superseded by `user_permissions` field. See `Types::PermissionTypes::Package` type',
          milestone: '16.6'
        },
        description: 'Whether the user can destroy the package.'
      field :created_at, Types::TimeType, null: false, description: 'Date of creation.'
      field :metadata, Types::Packages::MetadataType,
        null: true,
        description: 'Package metadata.'
      field :name, GraphQL::Types::String, null: false, description: 'Name of the package.'
      field :package_protection_rule_exists, GraphQL::Types::Boolean,
        null: false,
        alpha: { milestone: '16.11' },
        description:
          'Whether any matching package protection rule exists for this package. ' \
          'Available only when feature flag `packages_protected_packages` is enabled.'
      field :package_type, Types::Packages::PackageTypeEnum, null: false, description: 'Package type.'
      field :project, Types::ProjectType, null: false, description: 'Project where the package is stored.'
      field :status, Types::Packages::PackageStatusEnum, null: false, description: 'Package status.'
      field :status_message, GraphQL::Types::String, null: true, description: 'Status message.'
      field :tags, Types::Packages::PackageTagType.connection_type, null: true, description: 'Package tags.'
      field :updated_at, Types::TimeType, null: false, description: 'Date of most recent update.'
      field :version, GraphQL::Types::String, null: true, description: 'Version string.'

      def project
        Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
      end

      def can_destroy
        Ability.allowed?(current_user, :destroy_package, object)
      end

      def package_protection_rule_exists
        return false if Feature.disabled?(:packages_protected_packages, object.project)

        object.matching_package_protection_rules.exists?
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
        end
      end
      # rubocop: enable GraphQL/ResolverMethodLength
    end
  end
end
