# frozen_string_literal: true

module Types
  # DeploymentTagType is a hash, authorized by the deployment
  # rubocop:disable Graphql/AuthorizeTypes
  class DeploymentTagType < BaseObject
    graphql_name 'DeploymentTag'
    description 'Tags for a given deployment'

    field :name,
      GraphQL::Types::String,
      description: 'Name of this git tag.'

    field :path,
      GraphQL::Types::String,
      description: 'Path for this tag.'

    field :web_path,
      GraphQL::Types::String,
      description: 'Web path for this tag.'
  end
  # rubocop:enable Graphql/AuthorizeTypes
end
