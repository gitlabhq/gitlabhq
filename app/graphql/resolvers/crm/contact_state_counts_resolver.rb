# frozen_string_literal: true

module Resolvers
  module Crm
    class ContactStateCountsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_crm_contact

      type Types::CustomerRelations::ContactStateCountsType, null: true

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search term to find contacts with.'

      argument :state, Types::CustomerRelations::ContactStateEnum,
        required: false,
        description: 'State of the contacts to search for.'

      def resolve(**args)
        CustomerRelations::ContactStateCounts.new(context[:current_user], object, args)
      end
    end
  end
end
