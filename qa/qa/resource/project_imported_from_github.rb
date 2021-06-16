# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class ProjectImportedFromGithub < Resource::Project
      def fabricate!
        self.import = true

        Page::Main::Menu.perform(&:go_to_create_project)

        Page::Project::New.perform do |project_page|
          project_page.click_import_project
          project_page.click_github_link
        end

        Page::Project::Import::Github.perform do |import_page|
          import_page.add_personal_access_token(@github_personal_access_token)
          import_page.import!(@github_repository_path, @name)
        end
      end
    end
  end
end
