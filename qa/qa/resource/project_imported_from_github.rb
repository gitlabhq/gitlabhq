# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class ProjectImportedFromGithub < Base
      attr_accessor :name
      attr_writer :personal_access_token, :github_repository_path

      attribute :group do
        Group.fabricate!
      end

      def fabricate!
        group.visit!

        Page::Group::Show.perform(&:go_to_new_project)

        Page::Project::New.perform(&:click_import_project)

        Page::Project::New.perform(&:click_github_link)

        Page::Project::Import::Github.perform do |import_page|
          import_page.add_personal_access_token(@personal_access_token)
          import_page.list_repos
          import_page.import!(@github_repository_path, @name)
        end
      end
    end
  end
end
