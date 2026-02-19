# frozen_string_literal: true

module Subscriptions
  class IssuableUpdated < BaseSubscription
    include Gitlab::Graphql::Laziness

    payload_type Types::IssuableType

    argument :issuable_id, Types::GlobalIDType[Issuable],
      required: true,
      description: 'ID of the issuable.'

    def authorized?(issuable_id:)
      authorize_object_or_gid!(
        :"read_#{issuable_id.model_class.to_ability_name}",
        gid: issuable_id
      )
    end
  end
end
