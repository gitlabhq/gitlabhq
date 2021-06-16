# frozen_string_literal: true

module Types
  module Packages
    class PackageType < ::Types::BaseObject
      graphql_name 'Package'
      description 'Represents a package in the Package Registry. Note that this type is in beta and susceptible to changes'

      authorize :read_package

      field :id, ::Types::GlobalIDType[::Packages::Package], null: false,
            description: 'ID of the package.'

      field :name, GraphQL::STRING_TYPE, null: false, description: 'Name of the package.'
      field :created_at, Types::TimeType, null: false, description: 'Date of creation.'
      field :updated_at, Types::TimeType, null: false, description: 'Date of most recent update.'
      field :version, GraphQL::STRING_TYPE, null: true, description: 'Version string.'
      field :package_type, Types::Packages::PackageTypeEnum, null: false, description: 'Package type.'
      field :tags, Types::Packages::PackageTagType.connection_type, null: true, description: 'Package tags.'
      field :project, Types::ProjectType, null: false, description: 'Project where the package is stored.'
      field :pipelines, Types::Ci::PipelineType.connection_type, null: true,
        description: 'Pipelines that built the package.'
      field :metadata, Types::Packages::MetadataType, null: true,
        description: 'Package metadata.'
      field :versions, ::Types::Packages::PackageType.connection_type, null: true,
        description: 'The other versions of the package.',
        deprecated: { reason: 'This field is now only returned in the PackageDetailsType', milestone: '13.11' }
      field :status, Types::Packages::PackageStatusEnum, null: false, description: 'Package status.'

      def project
        Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
      end

      def versions
        []
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
