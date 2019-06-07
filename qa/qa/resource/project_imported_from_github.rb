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

        Page::Project::New.perform do |page|
          page.click_import_project
        end

        Page::Project::New.perform do |page|
          page.click_github_link
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
