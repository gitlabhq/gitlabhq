# frozen_string_literal: true

module API
  module Entities
    class ProjectHook < Hook
      expose :project_id, documentation: { type: 'string', example: 1 }
      expose :issues_events, documentation: { type: 'boolean' }
      expose :confidential_issues_events, documentation: { type: 'boolean' }
      expose :note_events, documentation: { type: 'boolean' }
      expose :confidential_note_events, documentation: { type: 'boolean' }
      expose :pipeline_events, documentation: { type: 'boolean' }
      expose :wiki_page_events, documentation: { type: 'boolean' }
      expose :deployment_events, documentation: { type: 'boolean' }
      expose :feature_flag_events, documentation: { type: 'boolean' }
      expose :job_events, documentation: { type: 'boolean' }
      expose :releases_events, documentation: { type: 'boolean' }
      expose :emoji_events, documentation: { type: 'boolean' }
      expose :resource_access_token_events, documentation: { type: 'boolean' }
      expose :vulnerability_events, documentation: { type: 'boolean' }
    end
  end
end
