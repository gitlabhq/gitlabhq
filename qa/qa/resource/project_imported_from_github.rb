# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class ProjectImportedFromGithub < Resource::Project
      def fabricate!
        self.import = true
        super

        group.visit!

        Page::Group::Show.perform(&:go_to_new_project)
        go_to_import_page
        Page::Project::New.perform(&:click_github_link)

        Page::Project::Import::Github.perform do |import_page|
          import_page.add_personal_access_token(@github_personal_access_token)
          import_page.import!(@github_repository_path, @name)
        end
      end

      def go_to_import_page
        Page::Project::New.perform(&:click_import_project)
      end
    end
  end
end
