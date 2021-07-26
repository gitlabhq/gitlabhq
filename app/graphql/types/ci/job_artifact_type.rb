# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class JobArtifactType < BaseObject
      graphql_name 'CiJobArtifact'

      field :download_path, GraphQL::Types::String, null: true,
            description: "URL for downloading the artifact's file."

      field :file_type, ::Types::Ci::JobArtifactFileTypeEnum, null: true,
            description: 'File type of the artifact.'

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
