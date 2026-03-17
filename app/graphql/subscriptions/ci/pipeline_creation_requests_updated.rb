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
        authorize_object_or_gid!(:read_merge_request, gid: merge_request_id)
      end
    end
  end
end
