# frozen_string_literal: true

module Types
  module WorkItems
    class NamespaceWorkItemChangesPayloadType < Types::BaseObject # rubocop:disable Graphql/AuthorizeTypes -- authorization is enforced by the subscription's authorized? method
      graphql_name 'NamespaceWorkItemChangesPayload'

      field :action,
        Types::WorkItems::ChangeActionEnum,
        null: false,
        description: 'Action that triggered the change event.',
        experiment: { milestone: '19.3' }
      field :work_item_id,
        Types::GlobalIDType[::WorkItem],
        null: false,
        description: 'Global ID of the work item that changed.',
        experiment: { milestone: '19.3' }

      def work_item_id
        ::Gitlab::GlobalId.build(model_name: 'WorkItem', id: object[:work_item_id])
      end
    end
  end
end
