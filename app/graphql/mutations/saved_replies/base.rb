# frozen_string_literal: true

module Mutations
  module SavedReplies
    class Base < BaseMutation
      field :saved_reply, Types::SavedReplyType,
            null: true,
            description: 'Updated saved reply.'

      private

      def present_result(result)
        if result.success?
          {
            saved_reply: result[:saved_reply],
            errors: []
          }
        else
          {
            saved_reply: nil,
            errors: result.message
          }
        end
      end

      def feature_enabled?
        Feature.enabled?(:saved_replies, current_user, default_enabled: :yaml)
      end

      def find_object(id)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::Users::SavedReply].coerce_isolated_input(id)

        GitlabSchema.find_by_gid(id)
      end
    end
  end
end
