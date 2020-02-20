# frozen_string_literal: true

module QA
  module Resource
    class ProjectMilestone < Base
      attribute :id
      attribute :title

      attribute :project do
        Project.fabricate_via_api! do |resource|
          resource.name = 'project-with-milestone'
        end
      end

      def initialize
        @title = "project-milestone-#{SecureRandom.hex(4)}"
      end

      def api_get_path
        "/projects/#{project.id}/milestones/#{id}"
      end

      def api_post_path
        "/projects/#{project.id}/milestones"
      end

      def api_post_body
        {
          title: title
        }
      end
    end
  end
end
