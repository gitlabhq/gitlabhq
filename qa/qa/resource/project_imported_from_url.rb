# frozen_string_literal: true

module QA
  module Resource
    class ProjectImportedFromURL < Resource::Project
      def fabricate!
        self.import = true
        super

        group.visit!

        Page::Group::Show.perform(&:go_to_new_project)

        Page::Project::New.perform do |project_page|
          project_page.click_import_project
          project_page.click_repo_by_url_link
        end

        Page::Project::Import::RepoByURL.perform do |import_page|
          import_page.import!(@gitlab_repository_path, @name, group.full_path)
        end
      end
    end
  end
end
