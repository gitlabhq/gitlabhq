# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class ProjectImportedFromGithub < Project
      attr_accessor :name
      attr_writer :personal_access_token, :github_repository_path

      attribute :group do
        Group.fabricate!
      end

      def fabricate!
        group.visit!

        Page::Group::Show.perform(&:go_to_new_project)

        Page::Project::New.perform do |page|
          page.go_to_import_project
        end

        Page::Project::New.perform do |page|
          page.go_to_github_import
        end

        Page::Project::Import::Github.perform do |page|
          page.add_personal_access_token(@personal_access_token)
          page.list_repos
          page.import!(@github_repository_path, @name)
        end
      end
    end
  end
end
