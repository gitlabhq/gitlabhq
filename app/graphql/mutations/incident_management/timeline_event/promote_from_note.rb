# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module TimelineEvent
      class PromoteFromNote < Base
        graphql_name 'TimelineEventPromoteFromNote'

        argument :note_id, Types::GlobalIDType[::Note],
                 required: true,
                 description: 'Note ID from which the timeline event promoted.'

        def resolve(note_id:)
          note = find_object(id: note_id)
          incident = note&.noteable

          authorize!(incident)

          response ::IncidentManagement::TimelineEvents::CreateService.new(
            incident,
            current_user,
            promoted_from_note: note,
            note: note.note,
            occurred_at: note.created_at
          ).execute
        end

        private

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::Note).sync
        end

        def authorize!(object)
          raise_noteable_not_incident! if object && !object.try(:incident?)

          super
        end

        def raise_noteable_not_incident!
          raise_resource_not_available_error! 'Note does not belong to an incident'
        end
      end
    end
  end
end
