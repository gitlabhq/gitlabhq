# frozen_string_literal: true

module Subscriptions
  class WorkItemUpdated < BaseSubscription
    include Gitlab::Graphql::Laziness

    payload_type Types::WorkItemType

    argument :work_item_id, Types::GlobalIDType[WorkItem],
      required: true,
      description: 'ID of the work item.'

    def authorized?(work_item_id:)
      authorize_object_or_gid!(:read_work_item, gid: work_item_id)
    end
  end
end
