# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class ChangedReviewer < BaseImporter
          def execute(issue_event)
            review_requester_id = author_id(issue_event, author_key: :review_requester)

            create_note(issue_event, review_requester_id)
          end

          private

          def create_note(issue_event, review_requester_id)
            created_note = Note.create!(
              importing: true,
              system: true,
              noteable_type: issuable_type(issue_event),
              noteable_id: issuable_db_id(issue_event),
              project: project,
              author_id: review_requester_id,
              note: parse_body(issue_event),
              system_note_metadata: SystemNoteMetadata.new(
                {
                  action: 'reviewer',
                  created_at: issue_event.created_at,
                  updated_at: issue_event.created_at
                }
              ),
              created_at: issue_event.created_at,
              updated_at: issue_event.created_at,
              imported_from: imported_from
            )

            return unless mapper.user_mapping_enabled?

            push_with_record(created_note, :author_id, issue_event[:review_requester]&.id, mapper.user_mapper)
          end

          def parse_body(issue_event)
            body = if issue_event.event == 'review_request_removed'
                     SystemNotes::IssuablesService.issuable_events[:review_request_removed]
                   else
                     SystemNotes::IssuablesService.issuable_events[:review_requested]
                   end

            "#{body} #{backticked_username(issue_event[:requested_reviewer])}"
          end
        end
      end
    end
  end
end
