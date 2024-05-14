# frozen_string_literal: true

module Resolvers
  module Crm
    class ContactsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include ResolvesIds

      authorize :read_crm_contact

      type Types::CustomerRelations::ContactType, null: true

      argument :sort, Types::CustomerRelations::ContactSortEnum,
        description: 'Criteria to sort contacts by.',
        required: false,
        default_value: { field: 'last_name', direction: :asc }

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search term to find contacts with.'

      argument :state, Types::CustomerRelations::ContactStateEnum,
        required: false,
        description: 'State of the contacts to search for.'

      argument :ids, [::Types::GlobalIDType[CustomerRelations::Contact]],
        required: false,
        description: 'Filter contacts by IDs.'

      def resolve(**args)
        args[:ids] = resolve_ids(args.delete(:ids))
        args.delete(:state) if args[:state] == :all

        contacts = ::Crm::ContactsFinder.new(current_user, { group: group }.merge(args)).execute
        if needs_offset?(args)
          offset_pagination(contacts)
        else
          contacts
        end
      end

      def group
        object.respond_to?(:sync) ? object.sync : object
      end

      private

      def needs_offset?(args)
        args.key?(:sort) && args[:sort][:field] == 'organization'
      end
    end
  end
end
