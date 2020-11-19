# frozen_string_literal: true

module API
  module Entities
    class ProjectHook < Hook
      expose :project_id, :issues_events, :confidential_issues_events
      expose :note_events, :confidential_note_events, :pipeline_events, :wiki_page_events, :deployment_events
      expose :job_events, :releases_events
      expose :push_events_branch_filter
    end
  end
end
