# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class JobArtifactType < BaseObject
      graphql_name 'CiJobArtifact'

      field :id, Types::GlobalIDType[::Ci::JobArtifact], null: false,
        description: 'ID of the artifact.'

      field :download_path, GraphQL::Types::String, null: true,
        description: "URL for downloading the artifact's file."

      field :file_type, ::Types::Ci::JobArtifactFileTypeEnum, null: true,
        description: 'File type of the artifact.'

      field :name, GraphQL::Types::String, null: true,
        description: 'File name of the artifact.',
        method: :filename

      field :size, GraphQL::Types::BigInt, null: false,
        description: 'Size of the artifact in bytes.'

      field :expire_at, Types::TimeType, null: true,
        description: 'Expiry date of the artifact.'

      def download_path
        ::Gitlab::Routing.url_helpers.download_project_job_artifacts_path(
          object.project,
          object.job,
          file_type: object.file_type
        )
      end
    end
  end
end
