# frozen_string_literal: true

module Subscriptions
  module Ci
    class PipelineCreationRequestsUpdated < ::Subscriptions::BaseSubscription
      include Gitlab::Graphql::Laziness

      payload_type Types::MergeRequestType

      argument :merge_request_id, Types::GlobalIDType[MergeRequest],
        required: true,
        description: 'Global ID of the merge request.'

      def authorized?(merge_request_id:)
        merge_request = force(GitlabSchema.find_by_gid(merge_request_id))
        unauthorized! unless merge_request && Ability.allowed?(current_user, :read_merge_request, merge_request)
        true
      end
    end
  end
end
