# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class CrmContactsType < BaseObject
        graphql_name 'WorkItemWidgetCrmContacts'
        description 'Represents CRM contacts widget'

        implements ::Types::WorkItems::WidgetInterface

        field :contacts,
          ::Types::CustomerRelations::ContactType.connection_type,
          null: true,
          description: 'Collection of CRM contacts associated with the work item.',
          method: :customer_relations_contacts

        field :contacts_available,
          GraphQL::Types::Boolean,
          null: false,
          description: 'Indicates whether contacts are available to be associated with the work item.'

        def contacts_available
          object.work_item.namespace.crm_group&.contacts&.exists? || false
        end
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
