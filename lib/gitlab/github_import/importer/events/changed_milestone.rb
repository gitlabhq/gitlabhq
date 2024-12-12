# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      module Events
        class ChangedMilestone < BaseImporter
          # GitHub API doesn't provide the historical state of an issue for
          # de/milestoned issue events. So we'll assign the default state to
          # those events that are imported from GitHub.
          DEFAULT_STATE = Issue.available_states[:opened]

          def execute(issue_event)
            create_event(issue_event)
          end

          private

          def create_event(issue_event)
            milestone = project.milestones.find_by_title(issue_event.milestone_title)
            return unless milestone

            attrs = {
              importing: true,
              user_id: author_id(issue_event),
              created_at: issue_event.created_at,
              milestone_id: milestone.id,
              action: action(issue_event.event),
              state: DEFAULT_STATE,
              imported_from: imported_from
            }.merge(resource_event_belongs_to(issue_event))

            created_event = ResourceMilestoneEvent.create!(attrs)

            return unless mapper.user_mapping_enabled?

            push_with_record(created_event, :user_id, issue_event[:actor]&.id, mapper.user_mapper)
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
