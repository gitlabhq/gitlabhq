# frozen_string_literal: true

module Mutations
  module Authz
    module AccessTokens
      class GranularScopeInputType < Types::BaseInputObject
        graphql_name 'GranularScopeInput'

        description 'Attributes for a granular scope of an access token.'

        argument :permissions, [GraphQL::Types::String], required: true,
          description: 'List of permissions for the granular scope.'

        argument :access, Types::Authz::AccessTokens::GranularScopeAccessEnum, required: true,
          description: 'Access to configure for the granular scope.'

        argument :resource_ids, [Types::GlobalIDType], required: false,
          description: 'IDs of groups or projects to associate with each granular scope.'
      end
    end
  end
end
