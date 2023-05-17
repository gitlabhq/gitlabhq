# frozen_string_literal: true

module QA
  module Resource
    class ProjectWebHook < WebHookBase
      extend Integrations::WebHook::Smockerable

      attributes :disabled_until, :alert_status

      attribute :project do
        Project.fabricate_via_api! do |resource|
          resource.name = 'project-with-webhooks'
        end
      end

      EVENT_TRIGGERS = %i[
        issues
        job
        merge_requests
        note
        pipeline
        push
        releases
        tag_push
        wiki_page
        confidential_issues
        confidential_note
      ].freeze

      EVENT_TRIGGERS.each do |trigger|
        attribute "#{trigger}_events".to_sym do
          false
        end
      end

      def initialize
        super

        @push_events_branch_filter = []
      end

      def add_push_event_branch_filter(branch)
        @push_events_branch_filter << branch
      end

      def resource_web_url(resource)
        "/project/#{project.name}/~/hooks/##{resource[:id]}/edit"
      end

      def api_get_path
        "#{api_post_path}/#{api_response[:id]}"
      end

      def api_post_path
        "/projects/#{project.id}/hooks"
      end

      def api_post_body
        body = {
          id: project.id,
          url: url,
          enable_ssl_verification: enable_ssl_verification,
          token: token,
          push_events_branch_filter: @push_events_branch_filter.join(',')
        }
        EVENT_TRIGGERS.each_with_object(body) do |trigger, memo|
          attr = "#{trigger}_events"
          memo[attr.to_sym] = send(attr)
          memo
        end
      end
    end
  end
end
