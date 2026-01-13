# frozen_string_literal: true

module API
  module Entities
    class IntegrationBasic < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 75 }
      expose :title, documentation: { type: 'String', example: 'Jenkins CI' }
      expose :slug, documentation: { type: 'Integer', example: 'jenkins' } do |integration|
        integration.to_param.dasherize
      end
      expose :created_at, documentation: { type: 'DateTime', example: '2019-11-20T11:20:25.297Z' }
      expose :updated_at, documentation: { type: 'DateTime', example: '2019-11-20T12:24:37.498Z' }
      expose :active, documentation: { type: 'Boolean' }
      expose :commit_events, documentation: { type: 'Boolean' }
      expose :push_events, documentation: { type: 'Boolean' }
      expose :issues_events, documentation: { type: 'Boolean' }
      expose :incident_events, documentation: { type: 'Boolean' }
      expose :alert_events, documentation: { type: 'Boolean' }
      expose :confidential_issues_events, documentation: { type: 'Boolean' }
      expose :merge_requests_events, documentation: { type: 'Boolean' }
      expose :tag_push_events, documentation: { type: 'Boolean' }
      expose :deployment_events, documentation: { type: 'Boolean' }
      expose :note_events, documentation: { type: 'Boolean' }
      expose :confidential_note_events, documentation: { type: 'Boolean' }
      expose :pipeline_events, documentation: { type: 'Boolean' }
      expose :wiki_page_events, documentation: { type: 'Boolean' }
      expose :job_events, documentation: { type: 'Boolean' }
      expose :comment_on_event_enabled, documentation: { type: 'Boolean' }
      expose :inherited, documentation: { type: 'Boolean' } do |integration|
        integration.inherit_from_id.present?
      end
    end
  end
end

API::Entities::IntegrationBasic.prepend_mod
