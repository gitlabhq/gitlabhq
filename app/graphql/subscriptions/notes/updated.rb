# frozen_string_literal: true

module Subscriptions
  module Notes
    class Updated < Base
      include Gitlab::Utils::StrongMemoize

      payload_type Types::Notes::NoteType

      private

      def note_object
        return if object.nil?

        ::Gitlab::Database::LoadBalancing::SessionMap.current(object.load_balancer).use_primary do
          object.reset
        end
        object
      end
      strong_memoize_attr :note_object
    end
  end
end
