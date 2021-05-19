# frozen_string_literal: true

module Subscriptions
  class IssuableUpdated < BaseSubscription
    include Gitlab::Graphql::Laziness

    payload_type Types::IssuableType

    argument :issuable_id, Types::GlobalIDType[Issuable],
              required: true,
              description: 'ID of the issuable.'

    def subscribe(issuable_id:)
      nil
    end

    def authorized?(issuable_id:)
      # TODO: remove this check when the compatibility layer is removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      raise Gitlab::Graphql::Errors::ArgumentError, 'Invalid IssuableID' unless issuable_id.is_a?(GlobalID)

      issuable = force(GitlabSchema.find_by_gid(issuable_id))

      unauthorized! unless issuable && Ability.allowed?(current_user, :"read_#{issuable.to_ability_name}", issuable)

      true
    end
  end
end
