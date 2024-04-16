# frozen_string_literal: true

module Integrations
  module Test
    class ProjectService < Integrations::Test::BaseService
      include Integrations::ProjectTestData
      include Gitlab::Utils::StrongMemoize

      def project
        strong_memoize(:project) do
          integration.project
        end
      end

      private

      def data
        strong_memoize(:data) do
          case event || integration.default_test_event
          when 'push', 'tag_push'
            push_events_data
          when 'note', 'confidential_note'
            note_events_data
          when 'issue', 'confidential_issue'
            issues_events_data
          when 'merge_request'
            merge_requests_events_data
          when 'job'
            job_events_data
          when 'pipeline'
            pipeline_events_data
          when 'wiki_page'
            wiki_page_events_data
          when 'deployment'
            deployment_events_data
          when 'release'
            releases_events_data
          when 'award_emoji'
            emoji_events_data
          when 'current_user'
            current_user_events_data
          end
        end
      end
    end
  end
end

Integrations::Test::ProjectService.prepend_mod_with('Integrations::Test::ProjectService')
