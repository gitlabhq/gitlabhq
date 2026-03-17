# frozen_string_literal: true

module Subscriptions
  module Notes
    class Created < Base
      include Gitlab::Utils::StrongMemoize

      payload_type ::Types::Notes::NoteType

      private

      def note_object
        case object
        when ResourceEvent
          object.work_item_synthetic_system_note
        when Array
          object.first.work_item_synthetic_system_note(events: object)
        else
          object
        end
      end
      strong_memoize_attr :note_object
    end
  end
end
