# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class Issue < Base
      attr_writer :description, :milestone, :template, :weight

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-for-issues'
          resource.description = 'project for adding issues'
        end
      end

      attribute :id
      attribute :iid
      attribute :assignee_ids
      attribute :labels
      attribute :title

      def initialize
        @assignee_ids = []
        @labels = []
        @title = "Issue title #{SecureRandom.hex(8)}"
      end

      def fabricate!
        project.visit!

        Page::Project::Show.perform(&:go_to_new_issue)

        Page::Project::Issue::New.perform do |new_page|
          new_page.fill_title(@title)
          new_page.choose_template(@template) if @template
          new_page.fill_description(@description) if @description
          new_page.choose_milestone(@milestone) if @milestone
          new_page.create_new_issue
        end
      end

      def api_get_path
        "/projects/#{project.id}/issues/#{id}"
      end

      def api_post_path
        "/projects/#{project.id}/issues"
      end

      def api_post_body
        {
          assignee_ids: assignee_ids,
          labels: labels,
          title: title
        }.tap do |hash|
          hash[:milestone_id] = @milestone.id if @milestone
          hash[:weight] = @weight if @weight
        end
      end

      def api_put_path
        "/projects/#{project.id}/issues/#{iid}"
      end

      def set_issue_assignees(assignee_ids:)
        put_body = { assignee_ids: assignee_ids }
        response = put Runtime::API::Request.new(api_client, api_put_path).url, put_body

        unless response.code == HTTP_STATUS_OK
          raise ResourceUpdateFailedError, "Could not update issue assignees to #{assignee_ids}. Request returned (#{response.code}): `#{response}`."
        end

        QA::Runtime::Logger.debug("Successfully updated issue assignees to #{assignee_ids}")
      end
    end
  end
end
