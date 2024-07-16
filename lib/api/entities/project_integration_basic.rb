# frozen_string_literal: true

module API
  module Entities
    class ProjectIntegrationBasic < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 75 }
      expose :title, documentation: { type: 'string', example: 'Jenkins CI' }
      expose :slug, documentation: { type: 'integer', example: 'jenkins' } do |integration|
        integration.to_param.dasherize
      end
      expose :created_at, documentation: { type: 'dateTime', example: '2019-11-20T11:20:25.297Z' }
      expose :updated_at, documentation: { type: 'dateTime', example: '2019-11-20T12:24:37.498Z' }
      expose :active, documentation: { type: 'boolean' }
      expose :commit_events, documentation: { type: 'boolean' }
      expose :push_events, documentation: { type: 'boolean' }
      expose :issues_events, documentation: { type: 'boolean' }
      expose :incident_events, documentation: { type: 'boolean' }
      expose :alert_events, documentation: { type: 'boolean' }
      expose :confidential_issues_events, documentation: { type: 'boolean' }
      expose :merge_requests_events, documentation: { type: 'boolean' }
      expose :tag_push_events, documentation: { type: 'boolean' }
      expose :deployment_events, documentation: { type: 'boolean' }
      expose :note_events, documentation: { type: 'boolean' }
      expose :confidential_note_events, documentation: { type: 'boolean' }
      expose :pipeline_events, documentation: { type: 'boolean' }
      expose :wiki_page_events, documentation: { type: 'boolean' }
      expose :job_events, documentation: { type: 'boolean' }
      expose :comment_on_event_enabled, documentation: { type: 'boolean' }
      expose :inherited, documentation: { type: 'boolean' } do |integration|
        integration.inherit_from_id.present?
      end
    end
  end
end

API::Entities::ProjectIntegrationBasic.prepend_mod
