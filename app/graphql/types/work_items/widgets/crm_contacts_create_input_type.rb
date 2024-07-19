# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class CrmContactsCreateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetCrmContactsCreateInput'

        argument :contact_ids,
          [::Types::GlobalIDType[::CustomerRelations::Contact]],
          required: true,
          description: 'CRM contact IDs to set.',
          prepare: ->(ids, _ctx) { ids.map { |gid| gid.model_id.to_i } }
      end
    end
  end
end
