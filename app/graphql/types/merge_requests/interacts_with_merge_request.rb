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

      def merge_request_interaction(parent:, id: nil)
        # need the connection parent if called from a connection node:
        parent = parent.parent if parent.try(:field)&.connection?
        ::Users::MergeRequestInteraction.new(user: object, merge_request: parent, current_user: current_user)
      end
    end
  end
end
