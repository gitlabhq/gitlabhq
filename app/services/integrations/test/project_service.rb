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
          next pipeline_events_data if integration.is_a?(::PipelinesEmailService)

          case event
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
          else
            push_events_data
          end
        end
      end
    end
  end
end

Integrations::Test::ProjectService.prepend_if_ee('::EE::Integrations::Test::ProjectService')
