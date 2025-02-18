# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class ChangedAssignee < BaseImporter
          def execute(issue_event)
            author_id = author_id(issue_event, author_key: :actor)

            note_body = parse_body(issue_event)

            created_note = create_note(issue_event, note_body, author_id)

            return unless mapper.user_mapping_enabled?

            push_with_record(created_note, :author_id, issue_event[:actor]&.id, mapper.user_mapper)
          end

          private

          def create_note(issue_event, note_body, author_id)
            Note.create!(
              importing: true,
              system: true,
              noteable_type: issuable_type(issue_event),
              noteable_id: issuable_db_id(issue_event),
              project: project,
              author_id: author_id,
              note: note_body,
              system_note_metadata: SystemNoteMetadata.new(
                {
                  action: "assignee",
                  created_at: issue_event.created_at,
                  updated_at: issue_event.created_at
                }
              ),
              created_at: issue_event.created_at,
              updated_at: issue_event.created_at,
              imported_from: imported_from
            )
          end

          def parse_body(issue_event)
            body = if issue_event.event == 'unassigned'
                     SystemNotes::IssuablesService.issuable_events[:unassigned]
                   else
                     SystemNotes::IssuablesService.issuable_events[:assigned]
                   end

            "#{body} #{backticked_username(issue_event[:assignee])}"
          end
        end
      end
    end
  end
end
