# frozen_string_literal: true

module Types
  module Packages
    class PackageType < BaseObject
      graphql_name 'Package'
      description 'Represents a package in the Package Registry'

      authorize :read_package

      field :id, GraphQL::ID_TYPE, null: false, description: 'The ID of the package.'
      field :name, GraphQL::STRING_TYPE, null: false, description: 'The name of the package.'
      field :created_at, Types::TimeType, null: false, description: 'The created date.'
      field :updated_at, Types::TimeType, null: false, description: 'The updated date.'
      field :version, GraphQL::STRING_TYPE, null: true, description: 'The version of the package.'
      field :package_type, Types::Packages::PackageTypeEnum, null: false, description: 'The type of the package.'
      field :tags, Types::Packages::PackageTagType.connection_type, null: true, description: 'The package tags.'
      field :project, Types::ProjectType, null: false, description: 'Project where the package is stored.'
      field :pipelines, Types::Ci::PipelineType.connection_type, null: true, description: 'Pipelines that built the package.'
      field :versions, Types::Packages::PackageType.connection_type, null: true, description: 'The other versions of the package.'

      def project
        Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
      end
    end
  end
end
