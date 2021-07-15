# frozen_string_literal: true

module API
  module Entities
    class ProjectIntegrationBasic < Grape::Entity
      expose :id, :title
      expose :slug do |integration|
        integration.to_param.dasherize
      end
      expose :created_at, :updated_at, :active
      expose :commit_events, :push_events, :issues_events, :confidential_issues_events
      expose :merge_requests_events, :tag_push_events, :note_events
      expose :confidential_note_events, :pipeline_events, :wiki_page_events
      expose :job_events, :comment_on_event_enabled
    end
  end
end
