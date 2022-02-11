# frozen_string_literal: true

module QA
  module Resource
    class ProjectWebHook < Base
      EVENT_TRIGGERS = %i[
        issues
        job
        merge_requests
        note
        pipeline
        push
        tag_push
        wiki_page
        confidential_issues
        confidential_note
      ].freeze

      attr_accessor :url, :enable_ssl, :id

      attribute :project do
        Project.fabricate_via_api! do |resource|
          resource.name = 'project-with-webhooks'
        end
      end

      EVENT_TRIGGERS.each do |trigger|
        attribute "#{trigger}_events".to_sym do
          false
        end
      end

      def initialize
        @id = nil
        @enable_ssl = false
        @url = nil
      end

      def resource_web_url(resource)
        "/project/#{project.name}/~/hooks/##{resource[:id]}/edit"
      end

      def api_get_path
        "/projects/#{project.id}/hooks"
      end

      def api_post_path
        api_get_path
      end

      def api_post_body
        body = {
          id: project.id,
          url: url,
          enable_ssl_verification: enable_ssl
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
