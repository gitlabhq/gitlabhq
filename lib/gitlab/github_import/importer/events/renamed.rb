# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class Renamed < BaseImporter
          def execute(issue_event)
            created_note = Note.create!(note_params(issue_event))

            return unless mapper.user_mapping_enabled?

            push_with_record(created_note, :author_id, issue_event[:actor]&.id, mapper.user_mapper)
          end

          private

          def note_params(issue_event)
            {
              importing: true,
              noteable_id: issuable_db_id(issue_event),
              noteable_type: issuable_type(issue_event),
              project_id: project.id,
              author_id: author_id(issue_event),
              note: parse_body(issue_event),
              system: true,
              created_at: issue_event.created_at,
              updated_at: issue_event.created_at,
              imported_from: imported_from,
              system_note_metadata: SystemNoteMetadata.new(
                {
                  action: "title",
                  created_at: issue_event.created_at,
                  updated_at: issue_event.created_at
                }
              )
            }
          end

          def parse_body(issue_event)
            old_diffs, new_diffs = Gitlab::Diff::InlineDiff.new(
              issue_event.old_title, issue_event.new_title
            ).inline_diffs

            marked_old_title = Gitlab::Diff::InlineDiffMarkdownMarker.new(issue_event.old_title).mark(old_diffs)
            marked_new_title = Gitlab::Diff::InlineDiffMarkdownMarker.new(issue_event.new_title).mark(new_diffs)

            "changed title from **#{marked_old_title}** to **#{marked_new_title}**"
          end
        end
      end
    end
  end
end
