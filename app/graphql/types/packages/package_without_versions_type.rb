# frozen_string_literal: true

module Types
  module Packages
    class PackageWithoutVersionsType < ::Types::BaseObject
      graphql_name 'PackageWithoutVersions'
      description 'Represents a version of a package in the Package Registry'

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

      def project
        Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
      end

      # NOTE: This method must be kept in sync with the union
      # type: `Types::Packages::MetadataType`.
      #
      # `Types::Packages::MetadataType.resolve_type(metadata, ctx)` must never raise.
      def metadata
        case object.package_type
        when 'composer'
          object.composer_metadatum
        else
          nil
        end
      end
    end
  end
end
