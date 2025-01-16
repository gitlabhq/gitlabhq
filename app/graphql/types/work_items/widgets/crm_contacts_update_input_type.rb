# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      class CrmContactsUpdateInputType < BaseInputObject
        graphql_name 'WorkItemWidgetCrmContactsUpdateInput'

        argument :contact_ids,
          [::Types::GlobalIDType[::CustomerRelations::Contact]],
          required: true,
          description: 'CRM contact IDs to set. Replaces existing contacts by default.',
          prepare: ->(ids, _ctx) { ids.map { |gid| gid.model_id.to_i } }

        argument :operation_mode,
          ::Types::MutationOperationModeEnum,
          required: false,
          default_value: ::Types::MutationOperationModeEnum.default_mode,
          description: 'Set the operation mode.'
      end
    end
  end
end
