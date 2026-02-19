# frozen_string_literal: true

module Subscriptions
  module Notes
    class Base < ::Subscriptions::BaseSubscription
      include Gitlab::Graphql::Laziness

      argument :noteable_id, ::Types::GlobalIDType[::Noteable],
        required: false,
        description: 'ID of the noteable.'

      def authorized?(noteable_id:)
        authorize_object_or_gid!(
          :"read_#{noteable_id.model_class.to_ability_name}",
          gid: noteable_id,
          object: note_object&.noteable
        )
      end

      def update(...)
        note_object
      end
    end
  end
end
