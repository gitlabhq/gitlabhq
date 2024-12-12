# frozen_string_literal: true

module TestHooks
  class ProjectService < TestHooks::BaseService
    include Integrations::ProjectTestData
    include Gitlab::Utils::StrongMemoize

    attr_writer :project

    def project
      @project ||= hook.project
    end

    private

    # rubocop:disable Metrics/CyclomaticComplexity -- despite a high count, this isn't that complex
    def data
      strong_memoize(:data) do
        case trigger
        when 'push_events'
          push_events_data
        when 'tag_push_events'
          tag_push_events_data
        when 'note_events'
          note_events_data
        when 'issues_events', 'confidential_issues_events'
          issues_events_data
        when 'merge_requests_events'
          merge_requests_events_data
        when 'job_events'
          job_events_data
        when 'pipeline_events'
          pipeline_events_data
        when 'wiki_page_events'
          wiki_page_events_data
        when 'releases_events'
          releases_events_data
        when 'emoji_events'
          emoji_events_data
        when 'resource_access_token_events'
          access_tokens_events_data
        when 'project_events'
          project_events_data
        when 'vulnerability_events'
          vulnerability_events_data
        end
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
