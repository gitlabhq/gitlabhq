# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes -- reason above
      class EscalationStatusType < BaseObject
        graphql_name 'WorkItemWidgetEscalationStatus'
        description 'Represents the escalation status widget'

        authorize_granular_token skip_reason: :parent_authorizes

        implements ::Types::WorkItems::WidgetInterface

        field :escalation_status, ::Types::IncidentManagement::EscalationStatusEnum,
          null: true,
          description: 'Escalation status of the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
