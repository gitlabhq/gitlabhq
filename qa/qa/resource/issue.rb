# frozen_string_literal: true

module QA
  module Resource
    class Issue < Base
      attr_writer :description, :milestone

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-for-issues'
          resource.description = 'project for adding issues'
        end
      end

      attribute :id
      attribute :labels
      attribute :title

      def initialize
        @labels = []
      end

      def fabricate!
        project.visit!

        Page::Project::Show.perform(&:go_to_new_issue)

        Page::Project::Issue::New.perform do |page|
          page.add_title(@title)
          page.add_description(@description)
          page.create_new_issue
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
          labels: labels,
          title: title
        }.tap do |hash|
          hash[:milestone_id] = @milestone.id if @milestone
        end
      end
    end
  end
end
