# frozen_string_literal: true

module Subscriptions
  module Notes
    class Created < Base
      payload_type ::Types::Notes::NoteType

      def update(*args)
        case object
        when ResourceEvent
          object.work_item_synthetic_system_note
        when Array
          object.first.work_item_synthetic_system_note(events: object)
        else
          object
        end
      end
    end
  end
end
