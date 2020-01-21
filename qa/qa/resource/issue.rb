# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class Issue < Base
      attr_writer :description, :milestone, :weight

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
          new_page.add_title(@title)
          new_page.add_description(@description)
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
    end
  end
end
