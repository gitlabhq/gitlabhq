# frozen_string_literal: true

module QA
  module Resource
    class ProjectMilestone < Base
      attr_writer :start_date, :due_date

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
        }.tap do |hash|
          hash[:start_date] = @start_date if @start_date
          hash[:due_date] = @due_date if @due_date
        end
      end
    end
  end
end
