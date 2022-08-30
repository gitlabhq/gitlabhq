# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class Reopened < BaseImporter
          def execute(issue_event)
            create_event(issue_event)
            create_state_event(issue_event)
          end

          private

          def create_event(issue_event)
            Event.create!(
              project_id: project.id,
              author_id: author_id(issue_event),
              action: 'reopened',
              target_type: issuable_type(issue_event),
              target_id: issuable_db_id(issue_event),
              created_at: issue_event.created_at,
              updated_at: issue_event.created_at
            )
          end

          def create_state_event(issue_event)
            attrs = {
              user_id: author_id(issue_event),
              state: 'reopened',
              created_at: issue_event.created_at
            }.merge(resource_event_belongs_to(issue_event))

            ResourceStateEvent.create!(attrs)
          end
        end
      end
    end
  end
end
