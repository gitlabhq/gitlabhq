# frozen_string_literal: true

module Mutations
  module Organizations
    class Base < BaseMutation
      field :organization,
        ::Types::Organizations::OrganizationType,
        null: true,
        description: 'Organization after mutation.'

      argument :description, GraphQL::Types::String,
        required: false,
        description: 'Description of the organization.'

      argument :avatar, ApolloUploadServer::Upload,
        required: false,
        description: 'Avatar for the organization.'
    end
  end
end
