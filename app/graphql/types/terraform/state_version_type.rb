# frozen_string_literal: true

module Types
  module Terraform
    class StateVersionType < BaseObject
      include ::API::Helpers::RelatedResourcesHelpers

      graphql_name 'TerraformStateVersion'

      authorize :read_terraform_state

      field :id, GraphQL::Types::ID,
            null: false,
            description: 'ID of the Terraform state version.'

      field :created_by_user, Types::UserType,
            null: true,
            description: 'The user that created this version.'

      field :download_path, GraphQL::Types::String,
            null: true,
            description: "URL for downloading the version's JSON file."

      field :job, Types::Ci::JobType,
            null: true,
            description: 'The job that created this version.'

      field :serial, GraphQL::Types::Int,
            null: true,
            description: 'Serial number of the version.',
            method: :version

      field :created_at, Types::TimeType,
            null: false,
            description: 'Timestamp the version was created.'

      field :updated_at, Types::TimeType,
            null: false,
            description: 'Timestamp the version was updated.'

      def created_by_user
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.created_by_user_id).find
      end

      def download_path
        expose_path api_v4_projects_terraform_state_versions_path(
          id: object.project_id,
          name: object.terraform_state.name,
          serial: object.version
        )
      end

      def job
        Gitlab::Graphql::Loaders::BatchModelLoader.new(::Ci::Build, object.ci_build_id).find
      end
    end
  end
end
