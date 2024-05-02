# frozen_string_literal: true

module Resolvers
  module Crm
    class OrganizationsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include ResolvesIds

      authorize :read_crm_organization

      type Types::CustomerRelations::OrganizationType, null: true

      argument :sort, Types::CustomerRelations::OrganizationSortEnum,
        description: 'Criteria to sort organizations by.',
        required: false,
        default_value: { field: 'name', direction: :asc }

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search term used to find organizations with.'

      argument :state, Types::CustomerRelations::OrganizationStateEnum,
        required: false,
        description: 'State of the organization to search for.'

      argument :ids, [Types::GlobalIDType[CustomerRelations::Organization]],
        required: false,
        description: 'Filter organizations by IDs.'

      def resolve(**args)
        args[:ids] = resolve_ids(args.delete(:ids))
        args.delete(:state) if args[:state] == :all

        ::Crm::OrganizationsFinder.new(current_user, { group: group }.merge(args)).execute
      end

      def group
        object.respond_to?(:sync) ? object.sync : object
      end
    end
  end
end
