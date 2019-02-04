# frozen_string_literal: true

module QA
  module Resource
    class Issue < Base
      attr_writer :description

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-for-issues'
          resource.description = 'project for adding issues'
        end
      end

      attribute :title

      def fabricate!
        project.visit!

        Page::Project::Show.perform(&:go_to_new_issue)

        Page::Project::Issue::New.perform do |page|
          page.add_title(@title)
          page.add_description(@description)
          page.create_new_issue
        end
      end
    end
  end
end
