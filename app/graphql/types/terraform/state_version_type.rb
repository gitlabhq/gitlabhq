# frozen_string_literal: true

module Types
  module Terraform
    class StateVersionType < BaseObject
      graphql_name 'TerraformStateVersion'

      authorize :read_terraform_state

      field :id, GraphQL::ID_TYPE,
            null: false,
            description: 'ID of the Terraform state version'

      field :created_by_user, Types::UserType,
            null: true,
            authorize: :read_user,
            description: 'The user that created this version'

      field :job, Types::Ci::JobType,
            null: true,
            authorize: :read_build,
            description: 'The job that created this version'

      field :created_at, Types::TimeType,
            null: false,
            description: 'Timestamp the version was created'

      field :updated_at, Types::TimeType,
            null: false,
            description: 'Timestamp the version was updated'

      def created_by_user
        Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.created_by_user_id).find
      end

      def job
        Gitlab::Graphql::Loaders::BatchModelLoader.new(::Ci::Build, object.ci_build_id).find
      end
    end
  end
end
