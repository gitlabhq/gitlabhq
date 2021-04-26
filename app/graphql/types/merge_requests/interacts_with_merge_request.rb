# frozen_string_literal: true

module Types
  module MergeRequests
    module InteractsWithMergeRequest
      extend ActiveSupport::Concern

      included do
        field :merge_request_interaction,
              type: ::Types::UserMergeRequestInteractionType,
              null: true,
              extras: [:parent],
              description: "Details of this user's interactions with the merge request."
      end

      def merge_request_interaction(parent:)
        merge_request = closest_parent(::Types::MergeRequestType, parent)
        return unless merge_request

        Users::MergeRequestInteraction.new(user: object, merge_request: merge_request)
      end
    end
  end
end
