# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class ChangedReviewer < BaseImporter
          def execute(issue_event)
            requested_reviewer_id = author_id(issue_event, author_key: :requested_reviewer)
            review_requester_id = author_id(issue_event, author_key: :review_requester)

            note_body = parse_body(issue_event, requested_reviewer_id)

            create_note(issue_event, note_body, review_requester_id)
          end

          private

          def create_note(issue_event, note_body, review_requester_id)
            Note.create!(
              importing: true,
              system: true,
              noteable_type: issuable_type(issue_event),
              noteable_id: issuable_db_id(issue_event),
              project: project,
              author_id: review_requester_id,
              note: note_body,
              system_note_metadata: SystemNoteMetadata.new(
                {
                  action: 'reviewer',
                  created_at: issue_event.created_at,
                  updated_at: issue_event.created_at
                }
              ),
              created_at: issue_event.created_at,
              updated_at: issue_event.created_at
            )
          end

          def parse_body(issue_event, requested_reviewer_id)
            requested_reviewer = User.find(requested_reviewer_id).to_reference

            if issue_event.event == 'review_request_removed'
              "#{SystemNotes::IssuablesService.issuable_events[:review_request_removed]}" \
              " #{requested_reviewer}"
            else
              "#{SystemNotes::IssuablesService.issuable_events[:review_requested]}" \
              " #{requested_reviewer}"
            end
          end
        end
      end
    end
  end
end
