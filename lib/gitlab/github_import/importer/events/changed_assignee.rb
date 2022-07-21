# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class ChangedAssignee < BaseImporter
          def execute(issue_event)
            assignee_id = author_id(issue_event, author_key: :assignee)
            assigner_id = author_id(issue_event, author_key: :assigner)

            note_body = parse_body(issue_event, assigner_id, assignee_id)

            create_note(issue_event, note_body, assigner_id)
          end

          private

          def create_note(issue_event, note_body, assigner_id)
            Note.create!(
              system: true,
              noteable_type: Issue.name,
              noteable_id: issue_event.issue_db_id,
              project: project,
              author_id: assigner_id,
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

          def parse_body(issue_event, assigner_id, assignee_id)
            Gitlab::I18n.with_default_locale do
              if issue_event.event == "unassigned"
                "unassigned #{User.find(assigner_id).to_reference}"
              else
                "assigned to #{User.find(assignee_id).to_reference}"
              end
            end
          end
        end
      end
    end
  end
end
