# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class Closed < BaseImporter
          def execute(issue_event)
            create_event(issue_event)
            create_state_event(issue_event)
          end

          private

          def create_event(issue_event)
            return if event_outside_cutoff?(issue_event)

            created_event = Event.create!(
              project_id: project.id,
              author_id: author_id(issue_event),
              action: 'closed',
              target_type: issuable_type(issue_event),
              target_id: issuable_db_id(issue_event),
              created_at: issue_event.created_at,
              updated_at: issue_event.created_at,
              imported_from: imported_from
            )

            return unless mapper.user_mapping_enabled?

            push_with_record(created_event, :author_id, issue_event[:actor]&.id, mapper.user_mapper)
          end

          def create_state_event(issue_event)
            attrs = {
              importing: true,
              user_id: author_id(issue_event),
              source_commit: issue_event.commit_id,
              state: 'closed',
              close_after_error_tracking_resolve: false,
              close_auto_resolve_prometheus_alert: false,
              created_at: issue_event.created_at,
              imported_from: imported_from
            }.merge(resource_event_belongs_to(issue_event))

            state_event = ResourceStateEvent.create!(attrs)

            return unless mapper.user_mapping_enabled?

            push_with_record(state_event, :user_id, issue_event[:actor]&.id, mapper.user_mapper)
          end
        end
      end
    end
  end
end
