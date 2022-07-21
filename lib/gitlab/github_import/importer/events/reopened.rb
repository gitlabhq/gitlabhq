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
              target_type: Issue.name,
              target_id: issue_event.issue_db_id,
              created_at: issue_event.created_at,
              updated_at: issue_event.created_at
            )
          end

          def create_state_event(issue_event)
            ResourceStateEvent.create!(
              user_id: author_id(issue_event),
              issue_id: issue_event.issue_db_id,
              state: 'reopened',
              created_at: issue_event.created_at
            )
          end
        end
      end
    end
  end
end
