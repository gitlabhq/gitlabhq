# frozen_string_literal: true

module Types
  module Packages
    class PackageType < ::Types::BaseObject
      graphql_name 'Package'
      description 'Represents a package in the Package Registry. Note that this type is in beta and susceptible to changes'

      connection_type_class(Types::CountableConnectionType)

      authorize :read_package

      field :id, ::Types::GlobalIDType[::Packages::Package], null: false,
            description: 'ID of the package.'

      field :can_destroy, GraphQL::Types::Boolean, null: false, description: 'Whether the user can destroy the package.'
      field :created_at, Types::TimeType, null: false, description: 'Date of creation.'
      field :metadata, Types::Packages::MetadataType, null: true,
        description: 'Package metadata.'
      field :name, GraphQL::Types::String, null: false, description: 'Name of the package.'
      field :package_type, Types::Packages::PackageTypeEnum, null: false, description: 'Package type.'
      field :pipelines, Types::Ci::PipelineType.connection_type, null: true,
            description: 'Pipelines that built the package.',
            deprecated: { reason: 'Due to scalability concerns, this field is going to be removed', milestone: '14.6' }
      field :project, Types::ProjectType, null: false, description: 'Project where the package is stored.'
      field :status, Types::Packages::PackageStatusEnum, null: false, description: 'Package status.'
      field :tags, Types::Packages::PackageTagType.connection_type, null: true, description: 'Package tags.'
      field :updated_at, Types::TimeType, null: false, description: 'Date of most recent update.'
      field :version, GraphQL::Types::String, null: true, description: 'Version string.'
      field :versions, ::Types::Packages::PackageType.connection_type, null: true,
        description: 'Other versions of the package.',
        deprecated: { reason: 'This field is now only returned in the PackageDetailsType', milestone: '13.11' }

      def project
        Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
      end

      def versions
        []
      end

      def can_destroy
        Ability.allowed?(current_user, :destroy_package, object)
      end

      # NOTE: This method must be kept in sync with the union
      # type: `Types::Packages::MetadataType`.
      #
      # `Types::Packages::MetadataType.resolve_type(metadata, ctx)` must never raise.
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
        else
          nil
        end
      end
    end
  end
end
