# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class Closed
          attr_reader :project, :user_id

          def initialize(project, user_id)
            @project = project
            @user_id = user_id
          end

          # issue_event - An instance of `Gitlab::GithubImport::Representation::IssueEvent`.
          def execute(issue_event)
            create_event(issue_event)
            create_state_event(issue_event)
          end

          private

          def create_event(issue_event)
            Event.create!(
              project_id: project.id,
              author_id: user_id,
              action: 'closed',
              target_type: Issue.name,
              target_id: issue_event.issue_db_id,
              created_at: issue_event.created_at,
              updated_at: issue_event.created_at
            )
          end

          def create_state_event(issue_event)
            ResourceStateEvent.create!(
              user_id: user_id,
              issue_id: issue_event.issue_db_id,
              source_commit: issue_event.commit_id,
              state: ResourceStateEvent.states[:closed],
              close_after_error_tracking_resolve: false,
              close_auto_resolve_prometheus_alert: false,
              created_at: issue_event.created_at
            )
          end
        end
      end
    end
  end
end
