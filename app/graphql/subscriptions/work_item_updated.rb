# frozen_string_literal: true

module Subscriptions
  class WorkItemUpdated < BaseSubscription
    include Gitlab::Graphql::Laziness

    payload_type Types::WorkItemType

    argument :work_item_id, Types::GlobalIDType[WorkItem],
      required: true,
      description: 'ID of the work item.'

    def authorized?(work_item_id:)
      work_item = force(GitlabSchema.find_by_gid(work_item_id))

      unauthorized! unless work_item && Ability.allowed?(current_user, :"read_#{work_item.to_ability_name}", work_item)

      true
    end
  end
end
