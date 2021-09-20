# frozen_string_literal: true

module QA
  module Resource
    class ProjectIssueNote < Base
      attr_writer :body

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-for-issue-notes'
          resource.description = 'project for adding notes to issues'
        end
      end

      attribute :issue do
        Issue.fabricate! do |resource|
          resource.project = project
          resource.title = 'Issue for adding notes.'
          resource.description = 'Issue for adding notes.'
        end
      end

      attribute :id
      attribute :body

      def initialize
        @body = "Issue note body #{SecureRandom.hex(8)}"
      end

      def fabricate!
        issue.visit!

        Page::Project::Issue::Show.perform do |show|
          show.comment(@body)
        end
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      def api_get_path
        "/projects/#{project.id}/issues/#{issue.iid}/notes/#{id}"
      end

      def api_post_path
        "/projects/#{project.id}/issues/#{issue.iid}/notes"
      end

      def api_post_body
        {
          body: body
        }
      end
    end
  end
end
