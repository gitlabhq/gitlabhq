# frozen_string_literal: true

module Resolvers
  module Crm
    class OrganizationStateCountsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_crm_organization
      authorizes_object!

      type Types::CustomerRelations::OrganizationStateCountsType, null: true

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search term to find organizations with.'

      argument :state, Types::CustomerRelations::OrganizationStateEnum,
        required: false,
        description: 'State of the organizations to search for.'

      def resolve(**args)
        ::Crm::OrganizationsFinder.counts_by_state(context[:current_user], args.merge({ group: object }))
      end
    end
  end
end
