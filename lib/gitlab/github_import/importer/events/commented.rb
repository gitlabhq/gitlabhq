# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class Commented < BaseImporter
          def execute(issue_event)
            note = Representation::Note.from_json_hash(
              noteable_id: issue_event.issuable_id,
              noteable_type: issue_event.issuable_type,
              author: issue_event.actor&.to_hash,
              note: issue_event.body,
              created_at: issue_event.created_at,
              updated_at: issue_event.updated_at,
              note_id: issue_event.id,
              imported_from: imported_from
            )

            NoteImporter.new(note, project, client).execute
          end
        end
      end
    end
  end
end
