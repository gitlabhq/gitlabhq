# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class ChangedAssignee < BaseImporter
          def execute(issue_event)
            assignee_id = author_id(issue_event, author_key: :assignee)
            author_id = author_id(issue_event, author_key: :actor)

            note_body = parse_body(issue_event, assignee_id)

            create_note(issue_event, note_body, author_id)
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
              updated_at: issue_event.created_at
            )
          end

          def parse_body(issue_event, assignee_id)
            assignee = User.find(assignee_id).to_reference

            if issue_event.event == 'unassigned'
              "#{SystemNotes::IssuablesService.issuable_events[:unassigned]} #{assignee}"
            else
              "#{SystemNotes::IssuablesService.issuable_events[:assigned]} #{assignee}"
            end
          end
        end
      end
    end
  end
end
