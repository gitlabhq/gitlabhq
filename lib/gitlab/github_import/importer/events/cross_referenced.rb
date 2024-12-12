# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class CrossReferenced < BaseImporter
          def execute(issue_event)
            mentioned_in_record_class = mentioned_in_type(issue_event)
            mentioned_in_number = issue_event.source.dig(:issue, :number)
            mentioned_in_record = init_mentioned_in(
              mentioned_in_record_class, mentioned_in_number
            )
            return if mentioned_in_record.nil?

            user_id = author_id(issue_event)
            note_body = cross_reference_note_content(mentioned_in_record.gfm_reference(project))

            note = create_note(issue_event, note_body, user_id)

            track_activity(mentioned_in_record_class, note.author)
          end

          private

          def track_activity(mentioned_in_class, author)
            return if mentioned_in_class != Issue

            Gitlab::UsageDataCounters::IssueActivityUniqueCounter.track_issue_cross_referenced_action(
              author: author,
              project: project
            )
          end

          def create_note(issue_event, note_body, user_id)
            created_note = Note.create!(
              importing: true,
              system: true,
              noteable_type: issuable_type(issue_event),
              noteable_id: issuable_db_id(issue_event),
              project: project,
              author_id: user_id,
              note: note_body,
              system_note_metadata: SystemNoteMetadata.new(action: 'cross_reference'),
              created_at: issue_event.created_at,
              imported_from: imported_from
            )

            return created_note unless mapper.user_mapping_enabled?

            push_with_record(created_note, :author_id, issue_event[:actor]&.id, mapper.user_mapper)

            created_note
          end

          def mentioned_in_type(issue_event)
            is_pull_request = issue_event.source.dig(:issue, :pull_request).present?
            is_pull_request ? MergeRequest : Issue
          end

          # record_class - Issue/MergeRequest
          def init_mentioned_in(record_class, iid)
            db_id = fetch_mentioned_in_db_id(record_class, iid)
            return if db_id.nil?

            record = record_class.new(id: db_id, iid: iid)
            record.project = project
            record.namespace = project.project_namespace if record.respond_to?(:namespace)
            record.readonly!
            record
          end

          # record_class - Issue/MergeRequest
          def fetch_mentioned_in_db_id(record_class, number)
            sawyer_mentioned_in_adapter = Struct.new(:iid, :issuable_type, keyword_init: true)
            mentioned_in_adapter = sawyer_mentioned_in_adapter.new(
              iid: number, issuable_type: record_class.name
            )

            issuable_db_id(mentioned_in_adapter)
          end

          def cross_reference_note_content(gfm_reference)
            "#{::SystemNotes::IssuablesService.cross_reference_note_prefix}#{gfm_reference}"
          end
        end
      end
    end
  end
end
