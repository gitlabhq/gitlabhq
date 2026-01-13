# frozen_string_literal: true

module API
  module Entities
    class ProjectHook < Hook
      expose :project_id, documentation: { type: 'String', example: 1 }
      expose :issues_events, documentation: { type: 'Boolean' }
      expose :confidential_issues_events, documentation: { type: 'Boolean' }
      expose :note_events, documentation: { type: 'Boolean' }
      expose :confidential_note_events, documentation: { type: 'Boolean' }
      expose :pipeline_events, documentation: { type: 'Boolean' }
      expose :wiki_page_events, documentation: { type: 'Boolean' }
      expose :deployment_events, documentation: { type: 'Boolean' }
      expose :feature_flag_events, documentation: { type: 'Boolean' }
      expose :job_events, documentation: { type: 'Boolean' }
      expose :releases_events, documentation: { type: 'Boolean' }
      expose :milestone_events, documentation: { type: 'Boolean' }
      expose :emoji_events, documentation: { type: 'Boolean' }
      expose :resource_access_token_events, documentation: { type: 'Boolean' }
      expose :vulnerability_events, documentation: { type: 'Boolean' }
    end
  end
end
