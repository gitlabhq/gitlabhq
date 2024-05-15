# frozen_string_literal: true

module Subscriptions
  class IssuableUpdated < BaseSubscription
    include Gitlab::Graphql::Laziness

    payload_type Types::IssuableType

    argument :issuable_id, Types::GlobalIDType[Issuable],
      required: true,
      description: 'ID of the issuable.'

    def authorized?(issuable_id:)
      issuable = force(GitlabSchema.find_by_gid(issuable_id))

      unauthorized! unless issuable && Ability.allowed?(current_user, :"read_#{issuable.to_ability_name}", issuable)

      true
    end
  end
end
