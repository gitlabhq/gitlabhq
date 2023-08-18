# frozen_string_literal: true

module Types
  module AccessLevels
    class DeployKeyType < BaseObject
      graphql_name 'AccessLevelDeployKey'
      description 'Representation of a GitLab deploy key.'

      authorize :read_deploy_key

      field :id,
        type: GraphQL::Types::ID,
        null: false,
        description: 'ID of the deploy key.'

      field :title,
        type: GraphQL::Types::String,
        null: false,
        description: 'Title of the deploy key.'

      field :expires_at,
        type: Types::DateType,
        null: true,
        description: 'Expiration date of the deploy key.'

      field :user,
        type: Types::AccessLevels::UserType,
        null: false,
        description: 'User assigned to the deploy key.'
    end
  end
end
