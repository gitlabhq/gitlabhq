# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class ChangedMilestone
          attr_reader :project, :user_id

          # GitHub API doesn't provide the historical state of an issue for
          # de/milestoned issue events. So we'll assign the default state to
          # those events that are imported from GitHub.
          DEFAULT_STATE = Issue.available_states[:opened]

          def initialize(project, user_id)
            @project = project
            @user_id = user_id
          end

          # issue_event - An instance of `Gitlab::GithubImport::Representation::IssueEvent`.
          def execute(issue_event)
            create_event(issue_event)
          end

          private

          def create_event(issue_event)
            ResourceMilestoneEvent.create!(
              issue_id: issue_event.issue_db_id,
              user_id: user_id,
              created_at: issue_event.created_at,
              milestone_id: project.milestones.find_by_title(issue_event.milestone_title)&.id,
              action: action(issue_event.event),
              state: DEFAULT_STATE
            )
          end

          def action(event_type)
            return ResourceMilestoneEvent.actions[:remove] if event_type == 'demilestoned'

            ResourceMilestoneEvent.actions[:add]
          end
        end
      end
    end
  end
end
