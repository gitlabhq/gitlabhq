# frozen_string_literal: true

module Types
  module CustomerRelations
    # `object` is a hash. Authorization is performed by OrganizationStateCountsResolver
    class OrganizationStateCountsType < Types::BaseObject # rubocop:disable Graphql/AuthorizeTypes
      graphql_name 'OrganizationStateCounts'
      description 'Represents the total number of organizations for the represented states.'

      AVAILABLE_STATES = ::CustomerRelations::Organization.states.keys.push('all').freeze

      AVAILABLE_STATES.each do |state|
        field state,
          GraphQL::Types::Int,
          null: true,
          description: "Number of organizations with state `#{state.upcase}`"
      end

      def all
        object.values.sum
      end
    end
  end
end
