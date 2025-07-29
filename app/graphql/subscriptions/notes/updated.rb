# frozen_string_literal: true

module Subscriptions
  module Notes
    class Updated < Base
      payload_type Types::Notes::NoteType

      private

      def update(*)
        ::Gitlab::Database::LoadBalancing::SessionMap.current(object.load_balancer).use_primary do
          object.reset
        end
        object
      end
    end
  end
end
