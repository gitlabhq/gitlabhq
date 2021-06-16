# frozen_string_literal: true

module QA
  module Resource
    class ProjectLabel < LabelBase
      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-with-label'
        end
      end

      def fabricate!
        project.visit!
        Page::Project::Menu.perform(&:go_to_labels)

        super
      end

      def api_post_path
        "/projects/#{project.id}/labels"
      end

      def api_get_path
        "/projects/#{project.id}/labels/#{id}"
      end
    end
  end
end
